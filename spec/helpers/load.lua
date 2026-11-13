return function(path, ns)
	ns = ns or {}
	assert(loadfile(path))("SimpleNotebook", ns)
	return ns
end
