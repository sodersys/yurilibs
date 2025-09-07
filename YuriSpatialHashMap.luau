--!strict
--!optimize 2
--[[
	Copyright © 2021 gopher town
	⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
	Distrubted under MIT license
--]]

--[[
	barebones 2D/3D spatial hashmap
	
	new(number, Vector3) -> (spatialHashMap)
		Internal function for scaling a vector3 to hash.
			getHash: (spatialHashMap: spatialHashMap, position: Vector3) -> (number),

		Sets an elements position, returns true if the position has changed its position in the map.
			set: (spatialHashMap: spatialHashMap, string, Vector3) -> (boolean),
			
		Adds an element to the map.
			add: (spatialHashMap: spatialHashMap, string, Vector3) -> (),

		Removes an element from the map.
			remove: (spatialHashMap: spatialHashMap, index: string) -> (),

		Checks in a square grid with sidelenth 2 * number + 1 for other elements in the map. Returns an array containing ElementIds
			checkAround: (spatialHashMap, string, number) -> ({string}),
]]

local config = {
	default_grid_size = 30,	
	default_map_center = Vector3.new(),
	limit_to_2D = true
}

export type spatialHashMap = {
	getHash: (spatialHashMap, Vector3) -> (Vector3),
	set: (spatialHashMap, string, Vector3) -> (boolean),
	add: (spatialHashMap, string, Vector3) -> (),
	remove: (spatialHashMap, string) -> (),
	checkAround: (spatialHashMap, string, number) -> ({string}),

	elements: {
		[string]: {
			position: Vector3,
		},
	},
	map: {
		[Vector3]: {
			[string]: boolean
		}
	},

	gridSize: number,
	mapCenter: Vector3,
	limitTo2D: boolean,
}

local function getHash(spatialHashMap: spatialHashMap, position: Vector3): Vector3
	local Hash = Vector3.new((position.X - spatialHashMap.mapCenter.X) // spatialHashMap.gridSize, spatialHashMap.limitTo2D and 0 or (position.X - spatialHashMap.mapCenter.Y) // spatialHashMap.gridSize, (position.Z - spatialHashMap.mapCenter.Z) // spatialHashMap.gridSize)

	if not spatialHashMap.map[Hash] then
		spatialHashMap.map[Hash] = {}
	end

	return Hash
end

local function set(spatialHashMap: spatialHashMap, element: string, position: Vector3): boolean
	local NewHash = spatialHashMap:getHash(position)
	local OldHash = spatialHashMap.elements[element].position

	if NewHash == OldHash then
		return false
	end

	spatialHashMap.map[OldHash][element] = nil
	spatialHashMap.map[NewHash][element] = true
	spatialHashMap.elements[element].position = position

	return true
end

local function add(spatialHashMap: spatialHashMap, element: string, position: Vector3)
	local Hash = spatialHashMap:getHash(position)

	spatialHashMap.map[Hash][element] = true
	spatialHashMap.elements[element].position = position
end

local function remove(spatialHashMap: spatialHashMap, element: string)
	local Hash = spatialHashMap.elements[element].position

	spatialHashMap.map[Hash][element] = nil
	spatialHashMap.elements[element] = nil
end

local function checkAround(spatialHashMap: spatialHashMap, element: string, distance: number)
	local Hits: {string} = {}

	local ElementPosition = spatialHashMap.elements[element].position
	if spatialHashMap.limitTo2D then
		for X = -distance, distance, 1 do
			for Y = -distance, distance, 1 do
				local Hash = getHash(spatialHashMap, ElementPosition + Vector3.new(X * spatialHashMap.gridSize, 0, Y * spatialHashMap.gridSize))
				for Element in spatialHashMap.map[Hash] do
					if Element == element then
						continue
					end

					table.insert(Hits, Element)
				end

			end
		end
	else
		for X = -distance, distance, 1 do
			for Y = -distance, distance, 1 do
				for Z = -distance, distance, 1 do
					local Hash = getHash(spatialHashMap, ElementPosition + Vector3.new(X * spatialHashMap.gridSize, Y * spatialHashMap.gridSize, Z * spatialHashMap.gridSize))
					for Element in spatialHashMap.map[Hash] do
						if Element == element then
							continue
						end

						table.insert(Hits, Element)
					end
				end

			end
		end
	end

	return Hits
end

local publicFunctions = {}

function publicFunctions.new(passedConfig: {gridSize: number?, mapCenter: Vector3?, limitTo2D: boolean?}?): spatialHashMap
	local SpatialHashMap = {} :: spatialHashMap

	SpatialHashMap.elements = {}
	SpatialHashMap.gridSize = (passedConfig and passedConfig.gridSize) or config.default_grid_size
	SpatialHashMap.map = {}
	SpatialHashMap.mapCenter = (passedConfig and passedConfig.mapCenter) or config.default_map_center
	SpatialHashMap.limitTo2D = (passedConfig and passedConfig.limitTo2D) or config.limit_to_2D

	SpatialHashMap.add = add
	SpatialHashMap.checkAround = checkAround
	SpatialHashMap.getHash = getHash
	SpatialHashMap.remove = remove
	SpatialHashMap.set = set

	return SpatialHashMap
end

return publicFunctions
