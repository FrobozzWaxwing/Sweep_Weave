# SweepWeave

SweepWeave is an integrated development environment for creating interactive storyworlds. Storyworlds are computer games, or interactive fiction works, which focus on interaction with fictional characters as the central game mechanic, which track dynamic relationships between characters, (including, in particular, between non-player characters and the player character,) and which employ these simulated characters and relationships to assemble pieces of handcrafted content into a coherent narrative shaped, in part, by player choice.

SweepWeave is based on design work by Chris Crawford and Sasha Fenn, and has been coded and implemented by Sasha Fenn. The suite consists of a storyworld interpretter, written in html and javascript, and a storyworld editor, written in the Godot game engine. Storyworlds are written and scripted in the editor, projects can be saved as .json files, and storyworlds can be exported as standalone html pages, which combine the interpreter with a block of data unique to the storyworld, and which can be played in a web browser.

Storyworlds consist of a collection of characters and a collection of "encounters," which contain the game's story content.

***********
Characters:
***********

Each character has personality traits, which track their tendency to act in certain ways, and traits that track their relationship to the player character over the course of the game.

Both personality traits and relationship traits are tracked via "bounded numbers," which are numbers limited to the range: -1 to 1, (including the lower and upper limits within the range.)

***********
Encounters:
***********

Each encounter includes a title, a piece of main text that can describe events that happen within the story, a set of options for the player to choose from, such that they can respond to story events, and a set of reactions associated with each of these options, such that a specified character can react to the player's choice.

Authors can also change the settings of the encounter and the options available to the player, changing when encounters occur or when certain options are available for players to choose.

Each encounter has a single character associated with it as an "antagonist;" this character's personality and relationship traits are used by the game to determine which reaction occurs after the player has chosen an option. Each reaction has an associated script by which the game calculates the character's inclination to select that reaction; during play, the reaction with the highest inclination is selected. (Ties are broken by choosing the earlier reaction in the list of reactions for the option in question.)

Once a reaction has been selected by the a.i., the game may also change the relationships between any non-player character and the player character. This allows authors to set certain consequences to occur as a result of the player's choices. In turn, these consequences can carry over to later parts of the story, since character relationships can affect which encounters occur, at what time they occur, and how characters react to the player's actions.

Reactions may also cause a specific encounter to occur next, bypassing the usual methods used by the game to select which encounter occurs.

*********
Gameplay:
*********

A playthrough runs through the following process:

1) The game selects an encounter to display.
  1-A) If the reaction selected during the last encounter specifies an encounter to occur next, this encounter is displayed.
  1-B) Otherwise, the game tests each encounter in the storyworld, checking when it can occur and whether all of its prerequisites are met.
  1-C) The game then calculates the desirability of each valid encounter, displaying the most desirable encounter and displaying it to the player.
2) The game displays an encounter.
  2-A) The encounter's main text is displayed to the player.
  2-B) The game calculates each option's visibility and performability prerequisites, displaying only those which meet their visibility prerequisites, and only allowing players to choose one that meets both its visibility and performability prerequisites.
  2-C) If no options pass their visibility and performability prerequisites, or the encounter has no options, then the game ends with this encounter.
3) The player chooses an option.
4) The game selects a reaction for the encounter's antagonist to perform, and displays the text of this reaction to the player.
  4-A) The game calculates the inclination of each reaction associated with the option chosen by the player. This is done using the scripts associated with each reaction, which use the antagonist's personality and relationship traits.
  4-B) The reaction with the highest inclination is selected.
  4-C) The game resets the options panel to display only the option the player chose.
  4-D) The text of the selected reaction is displayed to the player. This text can, for example, describe the antagonist's actions in response to the player's choice.
  4-E) The relationship changes associated with the selected reaction are calculated, and the game changes the designated character relationships accordingly. (The relationships of any character in the game can be changed, during this phase.)
  4-F) The game takes note of whether or not the selected reaction forces a specific encounter to occur next, and, if so, of which encounter must occur.
5) The game returns to step 1, repeating this loop until the game runs out of valid encounters, or reaches an encounter without any performable options, at which point the story ends.

**********
Scripting:
**********

Storyworlds employ scripts for several sets of calculations. This section contains some technical details for those interested.

1) Reactions:

When the game calculates the inclinations for each reaction associated with a given option, it looks up two of the current antagonist's traits and blends them together. This "blend" operation is a weighted average of the two traits. A weighting factor of -1 will set the result equal to the first trait, a weight of 1 will set it equal to the second trait, and a weight of 0 will set it equal to the simple average of both traits, (i.e., adding up the value of both traits and dividing by two.)

If one normalizes the weight from a number between -1 and 1 to a number between 0 and 1, (which can be done by averaging the weight with the number 1,) then the algorithm for a blend calculation consists of the following:

Result = x * (1 - w) + y * w.

Here, "x" equals the value of the first trait, y equals the value of the second trait, and w equals the value of the normalized weight.

2) Consequences:

Once a reaction occurs, the game may change the value of various character relationships. Authors can determine what modifications are made by setting up "blend change" scripts. Simply select the character and pValue to modify, then choose a weight.

A weight of 0 will leave the relationship unchanged. A weight above 0 will increase the value of the relationship trait, (i.e., the selected pValue.) A weight below 0 will decrease the pValue.

The change made either increases or decreases the pValue a certain percentage of the distance towards the upper or lower limit. For example, a weight of 1 will increase the pValue 100% of the distance towards 1, (i.e., the pValue will be set to 1.) A weight of 0.5 will increase the pValue 50% of the distance from its present value to 1. For example, if the character's current level of affection for the player character equals 0.2, and the designated weight equals 0.5, then the character's affection for the player character will increase to 0.6.

The algorithm for blend change operations consists of the following:

Result = x * (1 - absolute_value_of(delta)) + delta.

Here, "x" is the current value of the relationship trait in question, and "delta" is the weighting factor.

3) Encounter Settings:

Encounters can have both prerequisites and target conditions. Prerequisites allow authors to set encounters to only occur when certain conditions are met, for example when another encounter has occurred earlier in the playthrough. Target conditions are used by the game to calculate the desirability of each encounter.

Target conditions use a distance calculation to determine the encounter's desirability.

4) Option Settings:

Options can also have prerequisites, which determine whether or not an option is visible should the encounter occur, as well as whether the player can choose the option when it is visible.

********
Credits:
********

SweepWeave is available as open source software under an MIT License. All storyworlds created with SweepWeave belong to their respective authors. You are free to publish your storyworlds as you please, including for commercial purposes.

Chris Crawford can be found online at http://erasmatazz.com/
Sasha Fenn can be found online at https://www.patreon.com/sasha_fenn
SweepWeave can be downloaded from http://www.emptiestvoid.com/encounter_system/

If you would like to help support me financially, you can do so through my Patreon page, reached via the second link above.
Thanks to my patrons for their encouragement and support:
Pamela Beck
Chris Conley
Jóhannes Ævarsson

You can contact me through Chris Crawford's Thaddeus discussion board, through our interactive storytelling workgroup on Slack, via github, or through my Patreon page. On github I am FrobozzWaxwing.

Thanks, and peace to you.
~Sasha Fenn

********
License:
********

MIT License

Copyright (c) 2020-2021 ~ Sasha Fenn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
