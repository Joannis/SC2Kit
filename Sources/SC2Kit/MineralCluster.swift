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
    
    public var approximateExpansionLocation: Position.World {
        var centerOfMass = self.centerOfMass
        
        // Offset the center of mass further
        let closestResource = self.closestResource(to: centerOfMass)
        let xDiff = centerOfMass.as2D.difference(inSpace: \.x, to: closestResource.worldPosition.as2D)
        let yDiff = centerOfMass.as2D.difference(inSpace: \.y, to: closestResource.worldPosition.as2D)
        centerOfMass.x += xDiff * 3
        centerOfMass.y += yDiff * 3
        
        let side = openSide(nearExpansion: centerOfMass)
        print(centerOfMass.x, centerOfMass.y, side)
        
        
        // Offset current center of mass by 4.5 away from the mineral line
        // 2 distance from the mineral line to mark the edge of a base
        // 2 to put it on the center of a tile, so the base is centered on the area
        // This puts an approximate center for standard a 5x5 base
        let offset: Float = 4.5
        
        switch side {
        case .left, .topLeft, .bottomLeft:
            centerOfMass.x -= offset
        case .right, .topRight, .bottomRight:
            centerOfMass.x += offset
        default:
            break
        }
        
        switch side {
        case .top, .topLeft, .topRight:
            centerOfMass.y -= offset
        case .bottom, .bottomLeft, .bottomRight:
            centerOfMass.y += offset
        default:
            break
        }
        
        return centerOfMass
    }
    
    private func openSide(nearExpansion expansion: Position.World) -> Side {
        var belowCount = 0
        var rightCount = 0
        
        for resource in resources {
            rightCount += resource.worldPosition.x > expansion.x ? 1 : -1
            belowCount += resource.worldPosition.y > expansion.y ? 1 : -1
        }
        
        let boundary = resources.count / 2
        
        if rightCount > boundary {
            if belowCount > boundary {
                return .bottomRight
            } else if -belowCount > boundary {
                return .topRight
            } else {
                return .right
            }
        } else if -rightCount > boundary {
            if belowCount > boundary {
                return .bottomLeft
            } else if -belowCount > boundary {
                return .topLeft
            } else {
                return .left
            }
        } else {
            if belowCount > boundary {
                return .bottom
            } else if -belowCount > boundary {
                return .top
            } else {
                fatalError("Unknown ideal location at \(expansion.x) \(expansion.y)")
            }
        }
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
