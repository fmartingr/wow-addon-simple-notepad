return function(path, ns)
	ns = ns or {}
	assert(loadfile(path))("SimpleNotepad", ns)
	return ns
end
