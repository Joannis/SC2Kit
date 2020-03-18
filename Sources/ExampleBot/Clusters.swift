import SC2Kit

extension GamestateHelper {
    func getClusters() -> [(MineralCluster, Position.World)] {
        self.cached(byKey: "mineral-clusters") {
            units.resources.formClusters().compactMap { cluster -> (MineralCluster, Position.World)? in
                return (cluster, cluster.expansionLocation)
            }
        }
    }
    
    func getClustersWithExpansion() -> [(MineralCluster, Position.World, SC2Unit<Hatchery>)] {
        self.cached(byKey: "expansions") {
            let hatcheries = units.owned(Hatchery.self)
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
}
