# Persona

A simple React application for a sales persona assessment. The app displays a series of questions and calculates a persona type based on user responses. Firebase is used for anonymous authentication and to persist progress.

## Getting Started

1. Install Node.js (version 18 or higher).
2. Install dependencies:
   ```bash
   npm install
   ```
3. Provide Firebase configuration at build time using the following globals:
   - `__app_id` – your application ID
   - `__firebase_config` – JSON stringified Firebase configuration
   - `__initial_auth_token` *(optional)* – initial authentication token
4. Start the app with your preferred bundler.

## Validation Script

Run the provided script to validate that all questions in `app.tsx` have unique IDs and exactly five options each:

```bash
node scripts/validate.js
```
