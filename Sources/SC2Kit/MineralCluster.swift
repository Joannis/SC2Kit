extension Array where Element == SC2Unit<Resources> {
    public func formClusters(maxDistance: Float = 15) -> [MineralCluster] {
        var resources = self
        var clusters = [MineralCluster]()
        
        func groupResources(nearby cluster: inout MineralCluster) {
            let originalCount = resources.count
            var offset = resources.count
            nextMineral: while offset > 0 {
                offset -= 1
                
                for resource in cluster.resources {
                    if resource.worldPosition.as2D.distanceXorY(to: resources[offset].worldPosition.as2D) <= maxDistance {
                        cluster.resources.append(resources.remove(at: offset))
                        continue nextMineral
                    }
                }
            }
            
            if resources.count != originalCount {
                // Call this recursively, not all minerals might be grouped yet
                // This might happen when the furthest mineral of a patch is used as the origin
                // The other edge might not be grouped with the cluster because of the distance
                groupResources(nearby: &cluster)
            }
        }
        
        while !resources.isEmpty {
            var cluster = MineralCluster(origin: resources.removeFirst())
            groupResources(nearby: &cluster)
            clusters.append(cluster)
        }
        
        return clusters
    }
}

public struct MineralCluster {
    public fileprivate(set) var resources: [SC2Unit<Resources>]
    
    init(origin: SC2Unit<Resources>) {
        resources = [origin]
    }
    
    public var remainingMinerals: Int {
        resources.minerals.reduce(0, { $0 + $1.mineralContents })
    }
    
    public var hasUnscoutedMinerals: Bool {
        resources.minerals.contains { $0.mineralContents == 0 }
    }
    
    public var centerOfMass: Position.World {
        var cumulativeX: Float = 0
        var cumulativeY: Float = 0
        var cumulativeZ: Float = 0
        
        for resource in resources {
            cumulativeX += resource.worldPosition.x
            cumulativeY += resource.worldPosition.y
            cumulativeZ += resource.worldPosition.z
        }
        
        return Position.World(
            x: cumulativeX / Float(resources.count),
            y: cumulativeY / Float(resources.count),
            z: cumulativeZ / Float(resources.count)
        )
    }
    
    public func closestResource(to position: Position.World) -> SC2Unit<Resources> {
        var resourceIterator = resources.makeIterator()
        guard var closestResource = resourceIterator.next() else {
            fatalError("Invalid empty mineral cluster")
        }
        
        while let nextResource = resourceIterator.next() {
            let nextResourcePosition = nextResource.worldPosition.as2D
            let closestResourcePosition = closestResource.worldPosition.as2D
            
            if position.as2D.distanceXY(to: nextResourcePosition) < position.as2D.distanceXY(to: closestResourcePosition) {
                closestResource = nextResource
            }
        }
        
        return closestResource
    }
    
    public var approximateExpansionLocation: Position.World {
        var centerOfMass = self.centerOfMass
        let closestResource = self.closestResource(to: centerOfMass)
        
        // Offset current center of mass by 4.5 away from the mineral line
        // 2 distance from the mineral line to mark the edge of a base
        // 2 to put it on the center of a tile, so the base is centered on the area
        // This puts an approximate center for standard a 5x5 base
        if closestResource.worldPosition.x > centerOfMass.x {
            centerOfMass.x -= 4
        } else {
            centerOfMass.x += 4
        }

        if closestResource.worldPosition.y > centerOfMass.y {
            centerOfMass.y -= 4
        } else {
            centerOfMass.y -= 4
        }
        
        return centerOfMass
    }
    
    public var visibility: AreaVisibility {
        var visibleCount = 0
        
        for resource in resources where resource.isVisible {
            visibleCount += 1
        }
        
        switch visibleCount {
        case 0:
            return .none
        case resources.count:
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
