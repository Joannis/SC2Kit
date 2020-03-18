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
    
    public func closestResource(to position: Position.World) -> SC2Unit<Resources> {
        return resources.nearestUnit(to: position.as2D)!
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
    
    public func furthestResources() -> (SC2Unit<Resources>, SC2Unit<Resources>)? {
        assert(resources.count >= 2)
        var furthestDistance: Float = 0
        var result: (SC2Unit<Resources>, SC2Unit<Resources>)?
        
        for l in 0..<resources.count {
            for r in l..<resources.count {
                let lhs = resources[l]
                let rhs = resources[r]
                let distance = lhs.worldPosition.as2D.distanceXY(to: rhs.worldPosition.as2D)
                
                if distance >= furthestDistance {
                    result = (lhs, rhs)
                    furthestDistance = distance
                }
            }
        }
        
        return result
    }
    
    public var expansionLocation: Position.World {
        var centerOfMass = self.centerOfMass
        guard let (lhs, rhs) = furthestResources() else {
            return centerOfMass
        }
        
        let minDistance: Float = 6.2
        let maxDistance = (lhs.worldPosition.as2D.distanceXY(to: rhs.worldPosition.as2D) / 2) + 1
        
        func balance(offsetMultiplier: Float, relativeTo position: Position.World2D) {
            let diffX = position.difference(inSpace: \.x, to: centerOfMass.as2D)
            let diffY = position.difference(inSpace: \.y, to: centerOfMass.as2D)
            
            // Substract current offset
            centerOfMass.x -= diffX
            centerOfMass.y -= diffY
            
            // Add the offset multiplied by the needed difference, achieving the preferred position
            centerOfMass.x += diffX * offsetMultiplier
            centerOfMass.y += diffY * offsetMultiplier
        }
        
        for _ in 0..<10 {
            var neededBalance = false
            
            for resource in resources {
                let maxDistance: Float = resource.minerals == nil ? maxDistance : 7.5
                
                let distance = resource.worldPosition.as2D.distanceXY(to: centerOfMass.as2D)
                if distance < minDistance {
                    neededBalance = true
                    // 4 (distance needed) / 2 (current distance) = 2 (multiplier of offset)
                    // 4 (distance needed) / 8 (current distance) = 0.5 (multiplier of offset)
                    let offsetMultiplier = minDistance / distance
                    balance(offsetMultiplier: offsetMultiplier, relativeTo: resource.worldPosition.as2D)
                } else if distance > maxDistance {
                    let offsetMultiplier = maxDistance / distance
                    balance(offsetMultiplier: offsetMultiplier, relativeTo: resource.worldPosition.as2D)
                }
            }
            
            if !neededBalance {
                return centerOfMass
            }
        }
        
        return centerOfMass
    }
    
    func averageDistanceToResoures(from position: Position.World) -> Float {
        var distance: Float = 0
        
        for resource in resources {
            distance += position.as2D.distanceXY(to: resource.worldPosition.as2D)
        }
        
        return distance / Float(resources.count)
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

enum Side {
    case top, bottom, left, right
    case topLeft, bottomLeft, topRight, bottomRight
}

public enum AreaVisibility {
    case full
    case partial
    case none
}
