# Game Specification: Biome Dice

## Overview

Biome Dice is a solo tile-laying game. The player builds a connected map from
biome tiles, then places matching dice on completed tiles. The goal is to
maximize the score of connected biome regions.

## Components

- Four biomes: Mountain, Forest, Meadow, and Water.
- Twenty map tiles:
  - three whole tiles for each biome;
  - two half-tile variants for each biome, paired with the next biome in the
    cycle Mountain → Forest → Meadow → Water → Mountain.
- Twenty dice in a shared bag: five dice of each biome.
- Each die is rolled with a random value from 1 to 6 at the start of a round.

## Setup

1. Shuffle the 20 map tiles into a face-down pile.
2. Shuffle the 20 dice into the bag.
3. Start with an empty board and no carried dice.
4. Begin the first round.

## Round sequence

### 1. Reveal tiles and roll dice

- Reveal up to five tiles from the pile. The final round may contain fewer than
  five tiles.
- Add dice from the bag until the player has up to five dice in hand.
- Carried dice from the previous round are returned to the hand first and are
  rolled again.
- If the bag is empty, the hand may contain fewer than five dice.

### 2. Place all revealed tiles

- The player must place every revealed tile before placing dice.
- The first tile may be placed anywhere.
- From then on, a new tile must share an edge with an existing tile.
- A whole tile occupies one board cell.
- A half tile placed on an empty cell occupies one half of that cell.
- A second half can complete a cell only when its biome pair exactly matches
  the first half already there.
- Tiles do not require a die.

### 3. Resolve dice

- A die may be placed only on a completed whole cell.
- The die biome must match one of the cell's biomes.
- Each cell can contain at most one die.
- A die that cannot or should not be placed can be:
  - **Kept** for the next round. It is rolled again next round.
  - **Returned** to the bag. It may be drawn again in a later round.
- Dice actions can be undone during the current dice phase.

## Controls

- Click a tile or die to select it.
- Drag a tile or die onto a highlighted legal board cell.
- Drag a die to **KEEP** or **BAG** to resolve it.
- **Undo** reverses the most recent placement or dice action.
- **Next round** becomes available after all revealed tiles and dice are
  resolved.
- **New game** resets the complete game.
- Right-drag the board to pan.
- Use the mouse wheel to zoom the board between 75% and 135%.

## End of the game

The game ends after the final tile round has been resolved. The final round is
played even when fewer than five tiles remain. When no tiles and no unresolved
dice remain, the phase changes to **Game Over** and the final score is shown.

## Scoring

The implementation finds every connected region of the same biome using
edge-adjacency.

For each region:

1. **Basic score:** add the values of all dice placed in that region.
2. **Series bonus:** collect the unique die values in the region. Every
   continuous run of at least three values earns five points per value in the
   run. For example, 2-3-4 scores 15 bonus points.
3. A value is counted once per region; duplicate dice values do not extend a
   series.

The total score is the sum of all region subtotals. Regions are reported live
in the HUD and the final total is shown at Game Over.

## Implemented UI

- The left side contains the interactive, zoomable board.
- The right side contains round state, phase instructions, revealed tiles, dice
  in hand, keep/bag drop zones, navigation, and the live score report.
- Legal tile and die destinations are highlighted automatically.
- The board uses distinct colors for the four biomes and shows half cells,
  completed cells, biome names, and placed die values.

## Remaining design decisions

- Whether series should be allowed to overlap or whether each die may belong to
  only one series.
  - yes
- Whether scoring should use every connected region, as currently implemented,
  or only the largest region of each biome.
  -only largest
- Whether the board should have a visible maximum size.
  - no
- Whether carried dice need a separate visual representation beyond the HUD
  count.
  - yes, keep smaller list with kept dices
