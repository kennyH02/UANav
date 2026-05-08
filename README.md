# Project Title: UANav

## Name of group members:

Matthew Gregg, Kenny Huang, Santino Viscariello, Tyler Robinson

## Project inspiration

Students and community members at the University at Albany’s uptown campus struggle with navigation, managing time, and finding rooms, buildings, and tunnel access.
First-year experiences and online complaints about campus navigation inspired this project. UANav will optimize campus routes by using multiple frameworks and APIs
to show a user's location, destination, and navigation to a clearly constructed path for the user's best experience.
It will also serve as an extension and complement to the campus's existing navigational map services.

Our application will use Flutter for the frontend and Supabase to store and deliver the campus graph data. Routing data will be provided through QGIS as GeoJSON and JSON graph files. The user can search for buildings and specific rooms to reach their exact destination efficiently. Our application stores map data locally so users
still have access to campus routes and locations as a fallback when no internet is available. Where Google and Apple Maps fail to meet these standards,
our app would give students the optimal route to their next destination. Given the campus shortcuts that students actually use. Without utilizing a confusing 2D map rendering attached to a wall.

The development team will handle updates to the maps and UI. As a result, users will provide real-time feedback on issues such as mapping inconsistencies and broken features.

## How to run

1. Visit https://developer.android.com/studio

- You can also view [this video](https://www.youtube.com/watch?v=ZXPUulPjl4c) till 1:35 for a visual walk-through of downloading Android Studio.

2. Download Android Studio Panda 4
3. In Android Studio, check the left panel for the “Plugin” option, and click it.
4. Make sure you download the “Dart” plugin for Android Studio.
5. Go back to “Projects” on the left panel.
6. Click on the three dots on the right-hand side
7. Open “Device Manager”
8. Select the “+” icon on the upper-left-hand side.
9. Select “Medium Phone”
10. Go to the addition settings, scroll down, and change the RAM from 2 GB to 4 GB
11. Click “Finish” and start the device by clicking the triangle icon pointing to the right side, right next to the three-dots icon in Device Manager, on the right side.
12. Visit https://github.com/kennyH02/UANav
13. Click on the green button labeled “Code”
14. On “Local”, make sure you are in HTTPS and Clone using the web URL.
15. You can either clone the repository with GitHub Desktop or via command-line interface (CLI) tools. I personally use GitHub Desktop.

- If in CLI, make sure that you save the GitHub repository somewhere safe, I would recommend ../Document/Github/UANAV, for example.

16. Once you have cloned the repository, open the code in VS Code.
17. Make sure your VS Code has the extensions of “Dart” and “Flutter”
18. Under the “uanav” folder, create a .env file.
19. On the first line of the .env file, please enter: SUPABASE_URL=
20. On the second line of the .env file, please enter: SUPABASE_ANON_KEY=
21. Save the .env file.

- Find the two keys on the document we provide via BrightSpace.

22. In VS Code, open the terminal, then run `flutter run --release`

- If this doesn’t work, just run
  `flutter run`, if interested, you can also visit https://docs.flutter.dev/testing/build-modes to learn about what each of them means.
