asteroid 0.2.0 by paramat
For latest stable Minetest back to 0.4.7 stable
Depends default
Licenses: code WTFPL, textures CC BY SA

A realm of asteroids and comets is created in the chosen volume, by default between y = 13000 and y = 14000.
Asteroids are rich in ironore.
Comets are made of waterice and snow and are surrounded by a misty atmosphere of water vapour which hides the nucleus from view.
Both are rich in mese blocks and both have weblike 'fissure' cave systems.
Asteroid stone can be crafted to default:cobble or dark stone bricks or slabs.
Comet ice and snow can be crafted to default:water_source.
Generation time per chunk can be up to a minute on my old slow laptop, progress is printed to the terminal.
Generation can be disabled without disabling the entire mod and it's nodes (parameter ONGEN = false).

Crafting
--------

default:cobble
S
S = asteroid:stone

asteroid:stonebrick x 4
SS
SS
S = asteroid:stone

asteroid:stonebrickslab x 4
SS
S = asteroid:stone

default:water_source
W
W = asteroid:waterice

default:water_source
S
S = asteroid:snode
