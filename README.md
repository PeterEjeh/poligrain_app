# Poligrain App

A comprehensive agricultural investment and e-commerce platform built with Flutter, connecting investors with farmers and facilitating agricultural product trading, with a focus on grain products.

## Features

- 🌾 **Agricultural Investment**

  - Investment campaigns for various crops
  - Structured investment options
  - Farm project tracking
  - Returns management
  - Investment portfolio analytics

- **Marketplace**

- Product browsing with categories
- Detailed product views with images and videos
- Real-time inventory tracking
- Advanced search and filtering

- 🛒 **Shopping Experience**

  - Cart management
  - Order processing
  - Multiple payment methods
  - Order status tracking

- 💰 **Transaction Management**

  - Secure payment processing
  - Investment and purchase transaction history
  - Refund processing
  - Analytics and summaries

- 👤 **User Profiles**
  - Multi-role support (Investor/Farmer/Buyer)
  - User authentication
  - Seller and farmer profiles
  - Investment portfolio management
  - Address management
  - Order history

## Technology Stack

- **Frontend:** Flutter
- **Backend:** AWS (Lambda, DynamoDB, API Gateway)
- **Authentication:** AWS Cognito
- **Storage:** AWS S3 with CloudFront CDN
- **API:** REST API with Amplify
- **State Management:** Provider

## Getting Started

### Prerequisites

1. Flutter SDK
2. AWS Account
3. Amplify CLI
4. VS Code or Android Studio

### Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/PeterEjeh/poligrain_app.git
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Amplify:

   ```bash
   amplify configure
   amplify init
   amplify push
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/models/` - Data models
- `lib/screens/` - UI screens
- `lib/services/` - Business logic and API services
- `lib/widgets/` - Reusable UI components
- `amplify/` - AWS Amplify configuration and backend code

## Contributing

1. Fork the Project
2. Create your Feature Branch
3. Commit your Changes
4. Push to the Branch
5. Open a Pull Request

## Documentation

For more detailed information, please refer to:

- [Authentication Guide](AUTHENTICATION_GUIDE.md)
- [Testing Guide](TESTING_GUIDE.md)
- [Database Schema](DATABASE_SCHEMA.md)
- [Backend Implementation](COMPLETE_BACKEND_IMPLEMENTATION.md)
