# Game Specification: Biome Dice (v5 — final for this round of design)

## Overview

Biome Dice is a solo tile-laying game. The player builds a connected map from
biome tiles, then places matching dice on completed tiles, aiming to
maximize the score of the largest connected region of each biome. The game
has three levels; reaching a score threshold during a playthrough unlocks the
next level's additional rule for the remainder of the game.

## Components

- Four biomes: Mountain, Forest, Meadow, and Water.
- Forty map tiles:
  - six whole tiles for each biome;
  - four half-tile variants for each biome, pairing **only with the other
    half of the same biome** to complete a whole cell.
- Twenty dice in a shared bag: five dice of each biome, values 1–6, rolled
  fresh each round.
- **Level 3 only:** a second, separate deck of task tiles (16 unique types,
  see below).

## Setup

1. Shuffle the 40 map tiles into a face-down pile.
2. Shuffle the 20 dice into the bag.
3. Start with an empty board, no carried dice, at Level 1.
4. Begin the first round.

## Round sequence

### 1. Reveal tiles and roll dice

- Reveal up to five tiles from the pile (fewer in the final round).
- Add dice from the bag until the player has up to five dice in hand; kept
  dice from the previous round return first and are rolled again.
- If the bag is empty, the hand may contain fewer than five dice.

### 2. Place all revealed tiles

- All revealed tiles must be placed this round.
- The first tile of the game may be placed anywhere; every tile after that
  must share an edge with an existing tile.
- A whole tile occupies one board cell; two same-biome half-tiles combine to
  complete one cell. Tiles do not require a die.
- **Level 2+:** a tile may only be placed inside the current circular map
  boundary (see below).

### 3. Resolve dice

- A die may be placed only on a completed whole cell of the matching biome.
  Each cell holds at most one die.
- An unplaced die can be **kept** for next round (reduces next round's bag
  draw by one) or **returned** to the bag.

## Levels

Level rules are **cumulative**: each new level keeps every rule from the
previous levels active and adds its own on top. So Level 3 is played with
the Level 2 circular map still in effect, plus the task-tile deck.

### Level 1 (starting level)

Base rules as above — no map restriction, no task tiles.

**Advance to Level 2 at 125 points**, reached at any point during the game.
This threshold represents placing roughly 80% of all rolled dice (≈32 of 40)
plus landing at least one bonus run of length 3 — i.e. solid, consistent
play rather than a lucky endgame.

### Level 2: circular map

- The map is restricted to a circle centered on the very first tile placed
  in the game.
- Recalculated **every round** from the current number of placed tiles `n`:
  - `A = n × 1.3` (30% spare room beyond what's actually on the board)
  - `r = √(A / π)`, rounded up to the nearest whole cell
- A grid cell is legal for tile placement only if its distance from the
  center is ≤ `r`, using true **Euclidean distance** (a real circle, not a
  Manhattan/diamond shape).
- Because `r` is recalculated from the growing tile count each round, the
  circle naturally expands over the game with no separate growth rule.

**Advance to Level 3 at 150 points** (cumulative game score, same running
total). This is higher than the Level 1→2 threshold because the circular
limit makes sustaining the same 80%-placement, multi-bonus-run performance
harder — 150 represents the 112-point placement baseline plus two length-3
bonus runs (2 × 15) instead of one, showing the player can still plan
efficiently under the tighter space.

### Level 3: task tiles

- A second deck of 16 unique task tiles is shuffled separately. One is drawn
  and placed each round, following the normal edge-adjacency placement rule
  like any other tile.
- Each task tile's condition is evaluated **at game end** based on the final
  board state around where it was placed.
- Completing a task tile's condition awards a **flat +10 points**, regardless
  of the condition's difficulty (confirmed as adequate — no per-task scaling).
- 16 task types (roughly 2x what a single playthrough will draw, to reduce
  repetition across replays):

  1. All dice in the same row as this tile have value 5.
  2. All 4 orthogonal neighbors have die value 1.
  3. This tile is surrounded by Mountain on all 4 sides.
  4. This tile is surrounded by Water on all 4 sides.
  5. All dice in the same column as this tile have value 6.
  6. The sum of the 4 orthogonal neighbors' die values is exactly 10.
  7. Two opposite diagonal neighbors have the same die value.
  8. The same-biome connected region this tile belongs to has at least 5
     tiles at game end.
  9. None of the 4 orthogonal neighbors are the same biome as this tile.
  10. All 4 orthogonal neighbors are all different biomes from each other.
  11. This tile does not neighbor any Water tile.
  12. The die on this tile has an even value.
  13. The die on this tile has an odd value of 3 or higher.
  14. At least 3 of the 4 orthogonal neighbors have a die placed on them.
  15. This tile sits on the boundary of the current circular map (Level 2)
      at game end.
  16. This tile's own die value plus the value on the opposite diagonal
      neighbor is a multiple of 5.

## Scoring

For each of the four biomes, find only the single largest connected region
(edge-adjacency). For that region:

1. **Basic score:** sum of the die values placed in the region.
2. **Series bonus:** find the single longest run of consecutive integers
   among the region's unique die values (e.g. 1, 3, 5, 2 → run 1-2-3). No
   overlapping runs — just the one longest. Runs shorter than 3 score
   nothing. Bonus = **5 points × run length** (3 = 15, 4 = 20, 5 = 25).

**Level 3 add-on:** + 10 points for each completed task tile condition.

Total score = sum of the four biome subtotals + task tile bonuses.

## Remaining open questions

- If more levels are added later beyond Level 3, the same escalation logic
  can be reused: base 112 + 15 points per additional expected bonus run,
  rounded up to the nearest ten.
