## Lab Activity 2: Discussion

In this activity, the application relies on a clear separation of concerns using a Model-View-Controller (MVC) inspired architecture combined with the Provider pattern for state management. 

- **Model (`product.dart`)**: Represents the data structure for the items retrieved from the API endpoint. It parses raw JSON data into strongly-typed Dart objects.
- **Service (`product_service.dart`)**: Handles the core business logic of data fetching. It interacts with the external API over HTTP to fetch the product list and converts the HTTP response using the Model.
- **Screens (`product_screen.dart`, `home_screen.dart`)**: Serve as the Views. They consume the data provided by the Future resolved from the Service layer and present it visually to the user.
- **Provider (`theme_provider.dart`)**: Manages the application's global state (like the dark/light mode toggle). The Screens listen to changes in this provider to dynamically rebuild the UI when state changes occur.

This design pattern ensures that UI components remain decoupled from API integration logic, making the code much easier to read, maintain, and scale for future laboratory tasks.