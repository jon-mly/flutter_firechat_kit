# firechat_kit

A Flutter plugin to implement a chat linked to your backend solution, based on Firebase
to your application with just a few lines of code.

## Solution

  * Powered by Google Firebase, based on **Firestore**
  * Open source plugin written in **Dart**
  * **Full** and **exclusive** data control
  * **Turn key** solution & **quick** integration
  * Designed for **iOS** and **Android** 
  * **BLoC** architecture
  * **Scalable**
  
## Features

  * Private and group conversations
  * Easy to convert or to distinguish from private to group
  * Anonymous authentication on Firebase, and accounts related to an ID of your choice
  (the user ID in your backend)
  * Text, Image, Video, Audio, GIF messages (related to your hosting solution)
  * User profiles directly into the Firebase database (phone number, email, name, 
  custom data)
  * User search
  * Custom data for the chatrooms into the Firebase database
  * Chatroom search
  * Paginated chatrooms streams
  * Paginated messages streams
  * Read receipts
  * Active users tracking in each chatrooms
  * Explicit and complete error handling
  * Local data caching capability
  * Send messages & update profile even offline
  * Configurable behaviour to your needs
  
## Get started

#### Firebase set up

If your application does not use Firebase for another feature, or if you have not
configured Firebase for your application yet, you can follow these steps : 

1. Go to the Firebase console
2. Create a new project 
3. Configure your application to use Firebase by following the step 3 of this tutorial : 
https://firebase.google.com/docs/flutter/setup

You do not need to import any other packages unless needed for another part of your app.

#### FirechatKit specific set up

In the Firebase dashboard, under **Authentication** > **Sign-in method**, enable
Anonymous Authentication

### Example app

You can find in the repository an app under `example`, that demonstrates how to 
implement FirechatKit in an application.
