asteroid 0.3.2 by paramat
For latest stable Minetest back to 0.4.7 stable
Depends default
Licenses: code WTFPL, textures CC BY-SA

A realm of asteroids and comets is created in the chosen volume, by default between y = 13000 and y = 14000.
2 perlin noises of differing scales create interpenetrating large and small structures.
Asteroids have muliple layers, outer to inner: dust, gravel, cobble and stone with ores.
Asteroid stone is rich in iron, mese crystal, copper, gold and diamond.
By crafting, stone can be broken down into cobble, cobble into gravel and gravel into dust.
Asteroid stone can be crafted to dark stone bricks or slabs.
Comets have layers of snow and ice blended with asteroid structure depending on depth below surface.
Comets are surrounded by a misty atmosphere of water vapour which hides the nucleus from view. The atmosphere has a smoother shape than the comet it surrounds.
Comet ice and snow can be crafted to default:water_source.
Both have weblike 'fissure' cave systems, but these do not pass through the lava cores of larger asteroids.
Generation time per chunk can be up to a minute on my old slow laptop, progress is printed to the terminal.
Generation can be disabled without disabling the nodes (parameter ONGEN = false).

Crafting
--------

asteroid:stonebrick x 4
SS
SS

asteroid:stonebrickslab x 4
SS

S = asteroid:stone