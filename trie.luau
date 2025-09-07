--!strict
--!optimize 2
--[[
    Copyright © 2025 gopher town
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    Distrubted under MIT license
--]]

--[[
	simple luau trie implimentation

	new() -> ()
		Inserts an array of strings into the trie. All values are made lowercase so it is not case sensitive.
			insert: (trie: Trie, values: {string}) -> (),
		
		Finds all possible values that start with a given substring.
			find: (trie: Trie, key: string) -> {string},
		
		Root node, contains the node that the trie is based from.
			root: TrieNode
			
	TrieNode
		Children contains all nodes that continue from the a value. All children tables are indexed with a single character and are traversed as:
		node.children["h"].children["e"].children["l"].children["l"].children["o"]
			children: {
				[string]: TrieNode
			},
			
		Stub just determines whether or not it is the last letter in a completed word.
			completedWord: boolean?
]]


type TrieNode = {
	children: {
		[string]: TrieNode
	},
	completedWord: boolean?
}

export type Trie = {
	root: TrieNode,
	insert: (trie: Trie, values: {string}) -> (),
	find: (trie: Trie, key: string) -> {string}
}


local function newNode(): TrieNode
	return { 
		children = {}, 
	}
end

local function insert(trie: Trie, values: {string})
	for i, value in values do
		value = value:lower()
		local last = trie.root
		for k, letter in value:split("") do
			if not last.children[letter] then
				last.children[letter] = newNode()
			end 
			last = last.children[letter]
		end
		last.completedWord = true
	end
end

local function getResults(results: {string}, parentNode: TrieNode, key: string): {string}
	if parentNode.completedWord then
		table.insert(results, key)
	end

	for next, node in parentNode.children do
		getResults(results, node, key .. next)
	end

	return results
end

local function find(trie: Trie, key: string): {string}
	local node = trie.root
	for i, character in key:lower():split("") do

		if not node.children[character] then
			return {}
		end

		node = node.children[character]
	end

	return getResults({}, node, key)	
end

local trie = {}

function trie.new(): Trie
	return {
		root = newNode(),
		insert = insert,
		find = find
	}
end

return trie
