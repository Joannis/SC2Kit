extension Array where Element == SC2Unit<Minerals> {
    public func formClusters(maxDistance: Float = 15) -> [MineralCluster] {
        var minerals = self
        var clusters = [MineralCluster]()
        
        func groupMinerals(nearby cluster: inout MineralCluster) {
            let originalCount = minerals.count
            var offset = minerals.count
            nextMineral: while offset > 0 {
                offset -= 1
                
                for mineral in cluster.mineralPatches {
                    if mineral.worldPosition.as2D.distanceXorY(to: minerals[offset].worldPosition.as2D) <= maxDistance {
                        cluster.mineralPatches.append(minerals.remove(at: offset))
                        continue nextMineral
                    }
                }
            }
            
            if minerals.count != originalCount {
                // Call this recursively, not all minerals might be grouped yet
                // This might happen when the furthest mineral of a patch is used as the origin
                // The other edge might not be grouped with the cluster because of the distance
                groupMinerals(nearby: &cluster)
            }
        }
        
        while !minerals.isEmpty {
            var cluster = MineralCluster(origin: minerals.removeFirst())
            groupMinerals(nearby: &cluster)
            clusters.append(cluster)
        }
        
        return clusters
    }
}

public struct MineralCluster {
    public fileprivate(set) var mineralPatches: [SC2Unit<Minerals>]
    
    init(origin: SC2Unit<Minerals>) {
        mineralPatches = [origin]
    }
    
    public var remainingMinerals: Int {
        mineralPatches.reduce(0, { $0 + $1.mineralContents })
    }
    
    public var hasUnscoutedMinerals: Bool {
        mineralPatches.contains { $0.mineralContents == 0 }
    }
    
    public var approximateExpansionLocation: Position.World {
        var cumulativeX: Float = 0
        var cumulativeY: Float = 0
        var cumulativeZ: Float = 0
        
        for minerals in mineralPatches {
            cumulativeX += minerals.worldPosition.x
            cumulativeY += minerals.worldPosition.y
            cumulativeZ += minerals.worldPosition.z
        }
        
        var averagePosition = Position.World2D(
            x: cumulativeX / Float(mineralPatches.count),
            y: cumulativeY / Float(mineralPatches.count)
        )
        
        var mineralIterator = mineralPatches.makeIterator()
        guard var closestMineral = mineralIterator.next() else {
            fatalError("Invalid empty mineral cluster")
        }
        
        while let nextMineral = mineralIterator.next() {
            let nextMineralPosition = nextMineral.worldPosition.as2D
            let closestMineralPosition = closestMineral.worldPosition.as2D
            
            if averagePosition.distanceXY(to: nextMineralPosition) < averagePosition.distanceXY(to: closestMineralPosition) {
                closestMineral = nextMineral
            }
        }
        
        // Offset current center of mass by 4.5 away from the mineral line
        // 2 distance from the mineral line to mark the edge of a base
        // 2 to put it on the center of a tile, so the base is centered on the area
        // This puts an approximate center for standard a 5x5 base
        if closestMineral.worldPosition.x > averagePosition.x {
            averagePosition.x -= 4
        } else {
            averagePosition.x += 4
        }

        if closestMineral.worldPosition.y > averagePosition.y {
            averagePosition.y += 4
        } else {
            averagePosition.y -= 4
        }
        
        return Position.World(x: averagePosition.x, y: averagePosition.y, z: cumulativeZ / Float(mineralPatches.count))
    }
    
    public var visibility: AreaVisibility {
        var visibleCount = 0
        
        for mineral in mineralPatches where mineral.isVisible {
            visibleCount += 1
        }
        
        switch visibleCount {
        case 0:
            return .none
        case mineralPatches.count:
            return .full
        default:
            return .partial
        }
    }
}

public enum AreaVisibility {
    case full
    case partial
    case none
}
