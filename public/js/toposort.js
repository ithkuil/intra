//https://github.com/marcelklehr/toposort

function toposort(edges) {
   var nodes = uniqueNodes(edges)
     , index = nodes.length
     , sorted = new Array(index)

  while (index) visit(nodes[0], [])

  return sorted

  function visit(node, predecessors) {
    if(predecessors.indexOf(node) >= 0) {
      throw new Error('Cyclic dependency: '+JSON.stringify(node))
    }

    var i = nodes.indexOf(node)
    
    // already visited
    if (i < 0) return;

    nodes.splice(i, 1)

    // outgoing edges
    var out = edges.filter(function(edge){
      return edge[0] === node
    })
    if (i = out.length) {
      var preds = predecessors.concat(node)
      do {
        visit(out[--i][1], preds)
      } while (i)
    }
    
    sorted[--index] = node
  }
}

function uniqueNodes(arr){
  var res = []
  for (var i = 0, len = arr.length; i < len; i++) {
    var edge = arr[i]
    if (res.indexOf(edge[0]) < 0) res.push(edge[0])
    if (res.indexOf(edge[1]) < 0) res.push(edge[1])
  }
  return res
}

window.toposport = toposort;