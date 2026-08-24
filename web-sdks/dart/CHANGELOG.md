## 2.0.0

* **BREAKING**: Vehicles are now identified by an opaque string `vehicle_id`
  minted by the API, replacing integer session indexes (GroupVAN #1061).
  * `Vehicle.index` (int) → `Vehicle.vehicleId` (String)
  * `BuyersGuideVehicle.index` (int) → `BuyersGuideVehicle.vehicleId` (String)
  * `VehicleSwapRequest.vehicleIndex` → `VehicleSwapRequest.vehicleId` (String)
  * `ProductListingRequest.vehicleIndex` → `ProductListingRequest.vehicleId` (String?)
  * `getPreviousPartTypes`, `getSwapData`, `getVehicleCategories`,
    `getIdentifixUrl`, `omniSearch`, and `searchProducts` now take a
    String `vehicleId` instead of an int `vehicleIndex`/`engineIndex`
* Vehicle ids expire after 30 idle days; the API returns a 400 for an
  expired or unknown id, and the vehicle must be re-selected to mint a
  fresh id.

## 0.0.1

* TODO: Describe initial release.
