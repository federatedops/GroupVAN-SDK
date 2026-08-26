## 2.2.0

* Cart items carry the vehicle they were selected for (GroupVAN #1077):
  * `CartItem.vehicleId` (String?) — pass the hashed vehicle id when adding
    an item; the same part under different vehicles is a separate cart line
  * `CartItem.vehicle` (Vehicle?) — populated on `addToCart` and
    `getCartItems` responses; null for items added without a vehicle

## 2.1.0

* Fleet CRUD (GroupVAN #1046):
  * `createFleet(name:)` — `POST /v3/vehicles/fleets`, returns the new `Fleet`
  * `addFleetVehicle(fleetId:, vehicleId:)` — `POST /v3/vehicles/fleets/{id}/vehicles`,
    returns the `Vehicle` with a fleet-scoped id
  * `removeFleetVehicle(fleetId:, vehicleId:)` — `DELETE /v3/vehicles/fleets/{id}/vehicles/{vehicleId}`
  * New exported models: `FleetCreateRequest`, `FleetAddVehicleRequest`

## 2.0.0

* **BREAKING**: Vehicles are now identified by an opaque string `vehicle_id`
  minted by the API, replacing integer session indexes (GroupVAN #1061).
  * `Vehicle.index` (int) → `Vehicle.id` (String)
  * `BuyersGuideVehicle.index` (int) → `BuyersGuideVehicle.id` (String)
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
