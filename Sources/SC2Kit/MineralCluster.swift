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
        var averageRelativeX: Float = 0
        var averageRelativeY: Float = 0
        
        for resource in resources {
            averageRelativeX += expansion.as2D.distance(inSpace: \.x, to: resource.worldPosition.as2D)
            averageRelativeY += expansion.as2D.distance(inSpace: \.y, to: resource.worldPosition.as2D)
        }
        
        averageRelativeX /= Float(resources.count)
        averageRelativeY /= Float(resources.count)
        
//        if abs(averageRelativeX) > 1 {
//            if abs(averageRelativeY) > 1 {
//                // Y is not important
//                return averageRelativeX < 0 ? .right : .left
//            }
        
        print(averageRelativeX, averageRelativeY)
            
            if averageRelativeY > 0 {
                // Top
                if averageRelativeX > 0 {
                    // Right
                    return .topRight
                } else {
                    // Left
                    return .topLeft
                }
            } else {
                // Bottom
                if averageRelativeX > 0 {
                    // Right
                    return .bottomRight
                } else {
                    // Left
                    return .bottomLeft
                }
            }
//        } else {
//            // X is not important
//            return averageRelativeY < 0 ? .bottom : .top
//        }
    }
    
    func averageDistanceToResoures(from position: Position.World) -> Float {
        var distance: Float = 0
        
        for resource in resources {
            distance += position.as2D.distanceXY(to: resource.worldPosition.as2D)
        }
        
        return distance / Float(resources.count)
    }
    
//    public func getExpansionLocation(in gamestate: GamestateHelper) -> Position.World? {
//        var centerOfMass = self.centerOfMass
//        // Offset current center of mass by 4.5 away from the mineral line
//        // 2 distance from the mineral line to mark the edge of a base
//        // 2 to put it on the center of a tile, so the base is centered on the area
//        // This puts an approximate center for standard a 5x5 base
//        let offset: Float = 4.5
//        let side = openSide(nearExpansion: centerOfMass)
//
//        switch side {
//        case .top:
//            centerOfMass.y -= offset
//        case .bottom:
//            centerOfMass.y += offset
//        case .left:
//            centerOfMass.x -= offset
//        case .right:
//            centerOfMass.x += offset
//        }
//
//        var x = Int(centerOfMass.x)
//        var y = Int(centerOfMass.y)
//
//        let placement = gamestate.gameInfo.placementGrid
//
//        func correctX() -> Bool {
//            // Y should be fine, now find the X
//            if !placement[x, y] {
//                let canMoveLeft = placement[x - 3, y]
//                let canMoveRight = placement[x + 3, y]
//
//                switch (canMoveLeft, canMoveRight) {
//                case (false, false):
//                    return false
//                case (true, false):
//                    x -= 3
//                case (false, true):
//                    x += 3
//                case (true, true):
//                    var left = centerOfMass
//                    left.x -= 3
//                    let leftEffectiveRange = averageDistanceToResoures(from: left)
//
//                    var right = centerOfMass
//                    right.x += 3
//                    let rightEffectiveRange = averageDistanceToResoures(from: right)
//
//                    if rightEffectiveRange < leftEffectiveRange {
//                        x -= 3
//                    } else {
//                        x += 3
//                    }
//                }
//
//                if !placement[x, y] {
//                    return false
//                }
//            }
//
//            if !placement[x + 1, y] {
//                x -= 2
//            } else if !placement[x + 2, y] {
//                x -= 1
//            } else if !placement[x - 1, y] {
//                x += 1
//            } else if !placement[x - 2, y] {
//                x += 2
//            }
//
//            return placement[x - 2, y] && placement[x + 2, y]
//        }
//
//        func correctY() -> Bool {
//            // X should be fine, now find the Y
//            if !placement[x, y] {
//                let canMoveTop = placement[x, y - 3]
//                let canMoveBottom = placement[x, y + 3]
//
//                switch (canMoveTop, canMoveBottom) {
//                case (false, false):
//                    return false
//                case (true, false):
//                    y -= 3
//                case (false, true):
//                    y += 3
//                case (true, true):
//                    var top = centerOfMass
//                    top.y -= 3
//                    let topEffectiveRange = averageDistanceToResoures(from: top)
//
//                    var bottom = centerOfMass
//                    bottom.y += 3
//                    let bottomEffectiveRange = averageDistanceToResoures(from: bottom)
//
//                    if topEffectiveRange < bottomEffectiveRange {
//                        y -= 3
//                    } else {
//                        y += 3
//                    }
//                }
//
//                if !placement[x, y] {
//                    return false
//                }
//            }
//
//            if !placement[x, y + 1] {
//                y -= 2
//            } else if !placement[x, y + 2] {
//                y -= 1
//            } else if !placement[x, y - 1] {
//                y += 1
//            } else if !placement[x, y - 2] {
//                y += 2
//            }
//
//            return placement[x, y - 2] && placement[x, y + 2]
//        }
//
//        switch side {
//        case .top, .bottom:
//            guard correctX(), correctY() else {
//                return nil
//            }
//        case .left, .right:
//            guard correctY(), correctX() else {
//                return nil
//            }
//        }
//
//        return Position.World(x: Float(x), y: Float(y), z: centerOfMass.z)
//    }
    
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
