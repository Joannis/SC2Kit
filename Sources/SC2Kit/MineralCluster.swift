extension Array where Element == Minerals {
    public func formClusters(maxDistance: Float = 15) -> [MineralCluster] {
        var minerals = self
        var clusters = [MineralCluster]()
        
        func groupMinerals(nearby cluster: inout MineralCluster) {
            let originalCount = minerals.count
            var offset = minerals.count
            nextMineral: while offset > 0 {
                offset -= 1
                
                for mineral in cluster.mineralPatches {
                    if mineral.worldPosition.distanceXY(to: minerals[offset].worldPosition) <= maxDistance {
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
    public fileprivate(set) var mineralPatches: [Minerals]
    
    init(origin: Minerals) {
        mineralPatches = [origin]
    }
    
    public var remainingMinerals: Int {
        mineralPatches.reduce(0, { $0 + $1.mineralContents })
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
