﻿#!/usr/bin/env python

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
        print(f'Got status x: {x}, y: {y}, dir: {dir}, state:{state}, score: {score}, energy: {energy}')
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
    

    # <summary>
    # Observations received
    # </summary>
    # <param name="o">list of observations</param>
    def GetObservations(self, o: typing.List[str]):
        print('Got observations: ', o)
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
        self.brain.set_observations(sensors)


    # <summary>
    # No observations received
    # </summary>
    def GetObservationsClean(self):
        print('Got observations:', '[]')
        sensors = ai.Sensors()
        self.brain.set_observations(sensors)
    

    # <summary>
    # Get Decision
    # </summary>
    # <returns>command string to new decision</returns>
    def GetDecision(self):

        action = self.brain.get_decision()
        n = random.randint(0,7)
        
        if action.action == 'pick_up':
            return "pegar_ouro"
        elif action.action == 'move_forward':
            return "andar"
        elif action.action == 'move_backwards':
            return "andar_re"
        elif action.action == 'turn_clockwise':
            return "virar_direita"
        elif action.action == 'turn_anticlockwise':
            return "virar_esquerda"
        elif action.action == 'step_out':
            pass
        elif action.action == 'shoot':
            return "atacar"

        # TODO: Missing actions:
        # - "pegar_anel"
        # - "pegar_powerup"

        return ""
