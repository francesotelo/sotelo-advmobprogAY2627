## Lab Activity 4: Discussion

This activity expanded the architecture by integrating a `UserService` to manage authentication and user sessions locally using `SharedPreferences`. 

- **State & Flow**: The application now routes through a `splash_screen` which checks for a persistent authentication token. If present, the user bypasses the login flow and proceeds directly to the main application. 
- **User Model & Profile UI**: The `user.dart` model successfully captures the JSON payload from the `/auth/login` endpoint. This data is read dynamically on the `profile_screen` to populate the user's avatar, metadata, and handles session termination via the logout function.
- **Dynamic Cart Integration**: The `cart_screen` now fetches the user's ID stored in `SharedPreferences` during its initialization, dynamically requesting the specific cart associated with the logged-in user rather than relying on a hardcoded ID.