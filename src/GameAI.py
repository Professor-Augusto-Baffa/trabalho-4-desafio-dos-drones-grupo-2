#!/usr/bin/env python

"""GameAI.py: INF1771 GameAI File - Where Decisions are made."""
#############################################################
#Copyright 2020 Augusto Baffa
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#############################################################
__author__      = "Augusto Baffa"
__copyright__   = "Copyright 2020, Rio de janeiro, Brazil"
__license__ = "GPL"
__version__ = "1.0.0"
__email__ = "abaffa@inf.puc-rio.br"
#############################################################

import random
from Map.Position import Position
import typing
import prolog.prologquery as ai
import logging

# <summary>
# Game AI Example
# </summary>
class GameAI():

    brain = ai.PrologQuery()
    player = Position()
    state = "ready"
    dir = "north"
    score = 0
    energy = 0

    def __init__(self) -> None:
        if logging.root.level >= logging.INFO:
            self.brain.disable_logging()

    # <summary>
    # Refresh player status
    # </summary>
    # <param name="x">player position x</param>
    # <param name="y">player position y</param>
    # <param name="dir">player direction</param>
    # <param name="state">player state</param>
    # <param name="score">player score</param>
    # <param name="energy">player energy</param>
    def SetStatus(self, x: int, y: int, dir: str, state: str, score: int, energy: int):
        logging.root.debug(f'Got status x: {x}, y: {y}, dir: {dir}, state:{state}, score: {score}, energy: {energy}')
        self.brain.set_position(x, y)
        self.brain.set_facing(dir)
        self.brain.set_energy(energy)
        self.brain.set_score(score)
        self.player.x = x
        self.player.y = y
        self.dir = dir.lower()

        self.state = state
        self.score = score
        self.energy = energy
    
    def receiveShotHit(self, agent: str):
        pass

    def receiveGotHit(self, agent: str):
        pass

    # <summary>
    # Observations received
    # </summary>
    # <param name="o">list of observations</param>
    def GetObservations(self, o: typing.List[str]):
        logging.root.debug('Got observations: ' + str(o))
        sensors = ai.Sensors()

        for s in o:
        
            if s == "blocked":
                sensors.impact = True
            
            elif s == "steps":
                sensors.steps = True
            
            elif s == "breeze":
                sensors.breeze = True

            elif s == "flash":
                sensors.flash = True

            elif s == "blueLight":
                # TODO: power up
                pass

            elif s == "redLight":
                sensors.glow = True

            elif s == "greenLight":
                pass

            elif s == "weakLight":
                pass

            elif 'enemy' in s:
                split_index = s.find('#')
                if split_index > -1:
                    distance = int(s[split_index + 1 : ])
                    self.brain.set_detected_enemy(distance)
        self.brain.set_observations(sensors)


    # <summary>
    # No observations received
    # </summary>
    def GetObservationsClean(self):
        logging.root.debug('Got observations: ' + '[]')
        sensors = ai.Sensors()
        self.brain.set_observations(sensors)

    # <summary>
    # Get list of observable adjacent positions
    # </summary>
    # <returns>List of observable adjacent positions</returns>
    def GetObservableAdjacentPositions(self) -> typing.List[Position]:
        # TODO: get adjacent positions from prolog
        ret: typing.List[Position] = []

        ret.append(Position(self.player.x - 1, self.player.y))
        ret.append(Position(self.player.x + 1, self.player.y))
        ret.append(Position(self.player.x, self.player.y - 1))
        ret.append(Position(self.player.x, self.player.y + 1))

        return ret


    # <summary>
    # Get next forward position
    # </summary>
    # <returns>next forward position</returns>
    def NextPosition(self) -> typing.Optional[Position]:

        ret: typing.Optional[Position] = None

        if self.dir == "north":
            ret = Position(self.player.x, self.player.y - 1)

        elif self.dir == "east":
                ret = Position(self.player.x + 1, self.player.y)

        elif self.dir == "south":
                ret = Position(self.player.x, self.player.y + 1)

        elif self.dir == "west":
                ret = Position(self.player.x - 1, self.player.y)

        return ret
    

    # <summary>
    # Get Decision
    # </summary>
    # <returns>command string to new decision</returns>
    def GetDecision(self):

        action = self.brain.get_decision()
        decision = ''

        try:
            if action.action == 'pick_up':
                decision = 'pegar'
            elif action.action == 'move_forward':
                decision = 'andar'
            elif action.action == 'move_backwards':
                decision = 'andar_re'
            elif action.action == 'turn_clockwise':
                decision = 'virar_direita'
            elif action.action == 'turn_anticlockwise':
                decision = 'virar_esquerda'
            elif action.action == 'step_out':
                pass
            elif action.action == 'shoot':
                decision = 'atacar'
        except Exception:
            pass

        self.brain.print_map()
        logging.root.debug(f'Got decision: {decision}')
        return decision
    
    def reset(self):
        self.brain.reset()

