## Lab Activity 3: Discussion

In this activity, the Cart endpoint was integrated successfully, relying on the MVC-inspired structure.

- **Model (`cart.dart`)**: Data structures `Cart` and `CartProduct` were created to accurately parse the JSON objects returned by the API endpoint.
- **Service (`cart_service.dart`)**: To fulfill the requirement of rendering only one user cart via `getById`, the `/carts/user/:id` endpoint was implemented. This isolates the HTTP request logic, safely returning the parsed data payload to the UI. The `addToCart` POST request is similarly abstracted here.
- **Screen (`cart_screen.dart`)**: Uses a `FutureBuilder` to fetch and render the user's cart asynchronously. To fulfill Enhancement 1, tapping a cart item queries `ProductService().getProductById()` to fetch full specifications, then routes directly to the shared `ProductDetailsScreen` without duplicating UI code.
- **State Updates (`home_screen.dart`)**: Added a FloatingActionButton that selectively hides based on the active tab index (Enhancement 2).