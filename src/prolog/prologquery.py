from pyswip import Prolog
import os
import typing
import re

class Sensors:
    
    def __init__(
        self, steps: bool = False, breeze: bool = False, flash: bool = False,
        glow: bool = False, impact: bool = False, scream: bool = False
    ) -> None:
        self.steps = steps
        self.breeze = breeze
        self.flash = flash
        self.glow = glow
        self.impact = impact
        self.scream = scream
    
    @staticmethod
    def from_dict(values: typing.Dict[str, str]) -> 'Sensors':
        steps = values['Steps'] == 'steps'
        breeze = values['Breeze'] == 'breeze'
        flash = values['Flash'] == 'flash'
        glow = values['Glow'] == 'glow'
        impact = values['Impact'] == 'impact'
        scream = values['Scream'] == 'scream'
        return Sensors(steps, breeze, flash, glow, impact, scream)
    
    def __repr__(self) -> str:
        sensors = ['steps', 'breeze', 'flash', 'glow', 'impact', 'scream']
        for i, sensor in enumerate(sensors):
            if self.__getattribute__(sensor):
                continue
            sensors[i] = 'no_' + sensor
        return f'({", ".join(sensors)})'

class Position:

    def __init__(self, x: int, y: int) -> None:
        self.x = x
        self.y = y
    
    def __repr__(self) -> str:
        return f'{self.x}, {self.y}'

class Goal:

    def __init__(self, type: str, value: typing.Optional[Position]) -> None:
        self.type = type
        self.value = value
    
    @staticmethod
    def from_str(value: str) -> 'Goal':
        re_match = re.match(r'([^(]+)', value)
        type = re_match.group(1)
        re_match = re.match(r'([^(]+)\(,\((\d+), ?(\d+)\)\)', value)
        if re_match is None:
            # No associated value
            return Goal(type, None)
        x = re_match.group(2)
        y = re_match.group(3)
        return Goal(type, Position(x, y))
    
    def __repr__(self) -> str:
        s = f'{self.type}'
        if self.value is not None:
            s += f'({self.value})'
        return s

class Action:

    def __init__(self, action: str) -> None:
        self.action = action
    
    @staticmethod
    def from_str(value: str) -> 'Action':
        return Action(value)
    
    def __repr__(self) -> str:
        return self.action
    
class Inventory:

    def __init__(self, ammo: int, power_ups: int, gold: int) -> None:
        self.ammo = ammo
        self.power_ups = power_ups
        self.gold = gold
    

class AgentDeadError(Exception):
    pass

class PrologQuery():

    def __init__(self):
        self.prolog = Prolog()
        print(__file__)
        package_dir = os.path.dirname(__file__)
        kb_file = f'{os.path.relpath(package_dir, start=os.curdir)}/pitfall.pl'
        self.prolog.consult(kb_file)
        
    def sense(self) -> Sensors:
        query = 'sense((Steps, Breeze, Flash, Glow, Impact, Scream))'
        result = self.get_first_result(query)
        try:
            return Sensors.from_dict(result)
        except:
            raise AgentDeadError
    
    def set_observations(self, sensors: Sensors):
        query = f'set_last_observation({sensors})'
        _ = self.get_first_result(query)
    
    def get_decision(self) -> Action:
        sensors = self.sense()
        _, action = self.learn(sensors)
        return action

    
    def learn(self, sensors: Sensors) -> typing.Tuple[Goal, Action]:
        query = f'learn({sensors}, Goal, Action)'
        result = self.get_first_result(query)
        goal_str = result['Goal']
        action_str = result['Action']
        goal = Goal.from_str(goal_str)
        action = Action.from_str(action_str)
        return goal, action
    
    def act(self, action: Action) -> None:
        query = f'act({action})'
        _ = self.get_first_result(query)
    
    def set_facing(self, dir: typing.Literal['north', 'south', 'east', 'west']):
        query = f'set_agent_facing({dir})'
        _ = self.get_first_result(query)

    def set_position(self, x: int, y: int):
        query = f'set_agent_position(({x, y}))'
        _ = self.get_first_result(query)

    def set_energy(self, energy: int):
        # TODO
        pass

    def set_score(self, score: int):
        # TODO
        pass
    
    def get_health(self) -> int:
        query = 'get_agent_health(Health)'
        result = self.get_first_result(query)
        health_str = result['Health']
        return int(health_str)
    
    def get_game_score(self) -> int:
        query = 'get_game_score(Score)'
        result = self.get_first_result(query)
        score_str = result['Score']
        return int(score_str)
    
    def _player_is_at_correct_position(self) -> bool:
        query = f'agent_position(AP), world_position(agent, AP).'
        result = self.get_first_result(query)
        return result is not None
    
    def move_forward(self) -> bool:
        self.act(Action('move_forward'))
        return self._player_is_at_correct_position()
        
    
    def turn_clockwise(self) -> bool:
        self.act(Action('turn_clockwise'))
        return True
    
    def pick_up(self):
        self.act(Action('pick_up'))
    
    def shoot(self):
        self.act(Action('shoot'))
    
    def step_out(self):
        self.act(Action('step_out'))
    
    def get_inventory(self) -> Inventory:
        query = 'get_inventory(Ammo,PowerUps).'
        res = self.get_first_result(query)
        ammo = int(res['Ammo'])
        power_ups = int(res['PowerUps'])
        query = 'collected(gold,Gold).'
        res = self.get_first_result(query)
        gold = int(res['Gold'])
        return Inventory(ammo, power_ups, gold)

    def get_first_result(self, query):
        for res in self.prolog.query(query):
            return res
        
    

if __name__ == "__main__":
    prolog = PrologQuery()
    print(prolog.get_first_result('last_observation(S)'))
    prolog.set_observations(Sensors(False, False, False, False, False, False))
    print(prolog.get_first_result('last_observation(S)'))
    print(prolog.get_decision())
    