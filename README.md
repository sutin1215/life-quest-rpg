# LifeQuest RPG

**Gamified RPG for KitaHack 2026**

LifeQuest RPG is a Flutter-based mobile application that turns your real-life goals and tasks into a fun and engaging role-playing game. Define your main quest, and the app's AI will generate a unique character for you, complete with a class, an origin story, and starter quests.

## Features

*   **AI-Powered Character Creation:** Simply describe yourself and your main goal, and our Fate Weaver AI will forge your unique hero, assigning a class, a backstory, and initial stats (STR, INT, DEX).
*   **Dynamic Quest Generation:** Add your daily tasks and let the AI Guildmaster categorize them, set rewards (XP and Gold), and align them with your character's stats.
*   **RPG-Style Progression:** Complete quests to earn XP, level up your hero, and increase your stats.
*   **Explore the World:** Journey through the Forbidden Lands, a world map filled with different zones, each with its own challenges and boss.
*   **Epic Boss Battles:** Confront and defeat powerful bosses in turn-based combat. Our AI Narrator will weave a unique story for each battle.
*   **Goblin Market:** Use your hard-earned gold to buy powerful items and boost your stats at the Goblin Market.
*   **Pixel Art Aesthetics:** Enjoy a retro-inspired pixel art style for your character and items.

## Technologies Used

*   **Frontend:** Flutter
*   **Backend:** Firebase
    *   **Authentication:** Anonymous user authentication to provide a unique ID for each player.
    *   **Cloud Firestore:** NoSQL database to store user data, quests, and game progress.
    *   **Firebase AI (Gemini):** For generating character details, quests, and battle narrations.
*   **APIs:**
    *   **DiceBear:** For generating unique pixel-art avatars for characters and items.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
*   Firebase CLI: [https://firebase.google.com/docs/cli](https://firebase.google.com/docs/cli)

### Installation

1.  Clone the repo
    ```sh
    git clone https://github.com/your_username_/life_quest_rpg.git
    ```
2.  Install Flutter packages
    ```sh
    flutter pub get
    ```
3.  Set up Firebase for your project. You will need to create a new Firebase project and add the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files.
4.  Run the app
    ```sh
    flutter run
    ```

## Gameplay

1.  **Awaken Your Hero:** On the first launch, you'll be prompted to describe yourself and your main quest. This will be used to generate your character.
2.  **Begin Your Journey:** After your character is created, you will be given three starter quests to get you going.
3.  **The Quest Board:** This is your main hub. Here you can see your current quests, add new ones, and track your character's stats.
4.  **The Forbidden Lands:** When you're feeling brave, head to the world map to challenge the bosses of different zones.
5.  **The Goblin Market:** Spend your gold on powerful items to aid you in your quests.

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.
