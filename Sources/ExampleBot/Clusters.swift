import SC2Kit

extension GamestateHelper {
    func getClusters() -> [(MineralCluster, Position.World)] {
        units.resources.formClusters().compactMap { cluster -> (MineralCluster, Position.World)? in
            return (cluster, cluster.approximateExpansionLocation)
        }
    }
    
    func getClustersWithExpansion() -> [(MineralCluster, Position.World, SC2Unit<Hatchery>)] {
        let hatcheries = units.owned.only(Hatchery.self)
        return getClusters().compactMap { cluster, position in
            for hatchery in hatcheries {
                let isNearCluster = hatchery.worldPosition.as2D.distanceXY(to: position.as2D) <= 15
                
                if isNearCluster {
                    return (cluster, position, hatchery)
                }
            }
            
            return nil
        }
    }
}
