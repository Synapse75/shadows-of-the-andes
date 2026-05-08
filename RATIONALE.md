# PROJECT RATIONALE: Shadows of the Andes

## Project Overview

"Shadows of the Andes" is an interactive turn-based strategy game developed in Godot 4.6 that dramatizes the historical Túpac Amaru II rebellion (1780-1781) against Spanish colonial rule in the Peruvian highlands. Rather than presenting history as passive narrative, the game invites players to inhabit decision-making roles as the rebel leader, managing resources, recruiting forces, controlling territory, and navigating the logistical constraints of mounting a resistance movement across geographically fragmented Andean terrain. The game begins in Tinta—the actual historical birthplace of the rebellion—and tasks players with progressively bringing 12 additional Andean settlements under their control while managing food production, unit movements across altitude zones, and tactical combat against Spanish forces. Victory is achieved when all 13 villages are controlled by the player; defeat occurs when all rebel units are eliminated.

## Educational Purpose & Course Connection

This project engages with GEC2115's core commitment to understanding Latin America through multiple disciplinary lenses. Specifically, it operationalizes historical knowledge about indigenous resistance, colonial geography, and pre-Columbian resource systems into interactive game mechanics. Rather than asking students to *read about* Andean verticality—the concept that pre-Columbian and colonial Andean societies structured resource production and trade across altitude zones (high: potatoes/llamas; medium: corn/quinoa; low: coca)—the game requires players to *make strategic decisions contingent upon* this geographic reality. By forcing resource production to depend on altitude-specific terrain, and by making movement between altitude zones time-consuming, the game communicates how Túpac Amaru II's rebellion was fundamentally constrained by Andean geography in ways that conventional historical narratives often gloss over.

The game also materializes the historical protagonist—Túpac Amaru II—not as a distant figure but as an agent whose decisions determine outcomes. The tutorial system explicitly names Túpac Amaru II and grounds the player's actions in his historical context ("Tupac Amaru II led his rebellion from the village of Tinta"), while gameplay mechanics (recruiting soldiers, gathering resources, managing territories) mirror actual logistical challenges that 18th-century rebellions faced. By embedding historical complexity into ludic systems rather than exposition, the game argues that interactive media is a legitimate pedagogical tool for teaching Latin American history to audiences (including non-specialists) who may be more engaged by doing than reading.

## Design References & Historical Grounding

The game's mechanical systems draw inspiration from historical and geographic scholarship on the Andes:

1. **Geographic Verticality**: The three-tier altitude system (high/medium/low) and corresponding resources (potatoes & llamas / corn & quinoa / coca) reflect actual ecological zones and production patterns documented in works on Andean ecology and pre-Columbian economies. The constraint that moving between altitude zones requires multi-turn travel reflects the genuine difficulty of inter-regional coordination in the pre-industrial Andes.

2. **Village Selection**: The 13 settlements in the game—Tinta, Tungasuca, Cusco, Marcapata, Paucartambo, and others—are historically attested locations in the Túpac Amaru II rebellion (1780-1781). This is not a fantasy map but a strategic abstraction of real Andean geography where the rebellion took place.

3. **Resource Management Mechanics**: The game's hunger/starvation system and food production constraints are designed to mirror genuine logistical challenges that the rebel army faced. Historical sources indicate that food scarcity was a persistent strategic limitation, making resource management a historically-grounded rather than arbitrary game system.

4. **Unit Types**: The inclusion of both "Rebel Army" (primary combat force) and "Female Corps" (higher-defense, lower-attack units) reflects historical documentation that indigenous women participated actively in Túpac Amaru II's rebellion, not as auxiliary support but as combatants and strategic decision-makers.

## Pedagogical Innovation

Most existing strategy games (Civilization, Total War, XCOM) are set in invented worlds or use Latin America only as an aesthetic backdrop without structural engagement with its history. This project is intentionally different: it treats Andean geography and 18th-century indigenous resistance not as flavor text but as the *foundation* of game mechanics. This approach has pedagogical value because it:

- **Makes history manipulable**: Players can ask "what if I had taken Cusco instead of Urcos?"—questions that develop historical counterfactual thinking.
- **Operationalizes complexity**: Rather than explaining why Túpac Amaru II's rebellion ultimately failed, the game's difficulty curve lets players *experience* the logistical constraints that made centralized coordination nearly impossible.
- **Centers indigenous agency**: The player is positioned as an indigenous leader making strategic decisions, not as a colonizer or external observer—a positioning that recalibrates whose perspective the game centers.

## Implementation & Technical Scope

The completed game includes:

- **Full turn-based game loop** with player action phases and automated resolution phases
- **13 strategically-placed villages** distributed across 4 camera views representing different Andean regions
- **Resource system** with 5 resource types, production/consumption mechanics, and altitude-based constraints
- **Combat system** with multi-unit tactical engagement, damage calculation, and unit death mechanics
- **Unit recruitment, movement, and state management** (stationed/moving/attacking states)
- **UI systems** for map navigation, resource display, unit management, and drag-and-drop unit assignment
- **End-game scenes** with victory and defeat conditions, narrative messaging, and smooth transitions
- **Interactive tutorial system** with spotlight overlays and contextual guidance tied to historical narrative
- **Complete scene architecture** in Godot with modular scene files, custom shaders for visual effects, and organized script hierarchy

The implementation represents approximately 4,000+ lines of GDScript across 20+ custom scripts, demonstrating substantial technical depth in game systems design and interactive narrative architecture.

## AI Disclaimer

**Use of AI Tools in Development**: GitHub Copilot was utilized in the following capacities during this project:

1. **Code scaffolding and syntax completion**: Copilot provided auto-complete suggestions for GDScript function signatures, reducing time spent on routine typing while I reviewed and validated all generated code for correctness.

2. **Function documentation and comments**: Copilot generated initial docstring templates and inline comments, which I edited for accuracy and clarity.

3. **Refactoring assistance**: When reorganizing code structure or optimizing algorithms, Copilot suggested patterns that I evaluated, tested, and approved before integration.

4. **Debugging support**: Copilot helped identify potential null-reference errors and logic bugs by suggesting verification checks; I implemented only those that were necessary and correct.

**What was NOT generated by AI**:
- Core game design and system architecture
- Game balance parameters and tuning
- Historical research and geographic data
- Creative decisions about mechanics, narrative framing, and user experience
- Logical problem-solving for complex systems (movement timing, combat resolution, resource dynamics)
- All critical thinking, playtesting, and iterative refinement

**Assessment**: Copilot was used as a *productivity tool* similar to a spell-checker or IDE autocomplete, not as a generative agent that "did the thinking." All significant creative and technical decisions were made by me; AI assistance was limited to routine coding tasks that I reviewed and validated.

## Conclusion

"Shadows of the Andes" demonstrates that interactive games can be rigorous vehicles for engaging with Latin American history, geography, and indigenous resistance movements. By making players grapple with Andean constraints, resource scarcity, and territorial strategy, the game invites non-specialists to understand the rebellion not as a historical curiosity but as a complex adaptive challenge. The project combines technical depth (game systems architecture), historical specificity (real villages and geographic constraints), and pedagogical innovation (mechanics-as-argument) to create an artifact that is both playable and intellectually substantive—a resource suitable for classroom use, historical education, or general audiences interested in interactive approaches to Latin American studies.

---

**Project Delivery**:
- Playable game in Godot 4.6 (playable on Windows; source code available)
- Complete design documentation (GDD.md included in repository)
- Organized source code with modular architecture (Scripts/, Scenes/, Sprites/ directories)
- Total development effort: equivalent to 1600+ word research paper in design, implementation, playtesting, and historical research

**Repository**: https://github.com/[user]/shadows-of-the-andes
