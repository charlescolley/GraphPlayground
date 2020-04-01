using SparseArrays


function draw_graph(A::SparseMatrixCSC)

header = """
	<!DOCTYPE html>
<meta charset="utf-8">
<body>
<script src="https://d3js.org/d3.v4.min.js"></script>

<style>

.links line {
  stroke: #999;
  stroke-opacity: 0.6;
}

.nodes circle {
  stroke: #fff;
  stroke-width: 1.5px;
}

</style>
<svg width="960" height="600"></svg>
<!--<script src="https://d3js.org/d3.v4.min.js"></script> -->
<script>
//create somewhere to put the force directed graph
var svg = d3.select("svg"),
    width = +svg.attr("width"),
    height = +svg.attr("height");
    
"""

#=
var nodes_data =  [
    {"name": "Travis", "sex": "M"},
    {"name": "Rake", "sex": "M"},
    {"name": "Diana", "sex": "F"},
    {"name": "Rachel", "sex": "F"},
    {"name": "Shawn", "sex": "M"},
    {"name": "Emerald", "sex": "F"}
    ]
//Create links data 
var links_data = [
    {"source": "Travis", "target": "Rake"},
    {"source": "Diana", "target": "Rake"},
    {"source": "Diana", "target": "Rachel"},
    {"source": "Rachel", "target": "Rake"},
    {"source": "Rachel", "target": "Shawn"},
    {"source": "Emerald", "target": "Rachel"}
]

=#


footer="""
//set up the simulation 
//nodes only for now 
var simulation = d3.forceSimulation()
					//add nodes
					.nodes(nodes_data);	
                    
//add forces
//we're going to add a charge to each node 
//also going to add a centering force
simulation
    .force("charge_force", d3.forceManyBody())
    .force("center_force", d3.forceCenter(width / 2, height / 2));



//Time for the links 



//Add a links force to the simulation
//Specify links  in d3.forceLink argument   



//add tick instructions: 
simulation.on("tick", tickActions );

//Create the link force 
//We need the id accessor to use named sources and targets 

var link_force =  d3.forceLink(links_data)
                        .id(function(d) { return d.name; })


simulation.force("links",link_force)

//draw lines for the links 
var link = svg.append("g")
      .attr("class", "links")
    .selectAll("line")
    .data(links_data)
    .enter().append("line")
      .attr("stroke-width", 2);        
                

//draw circles for the nodes 
var node = svg.append("g")
        .attr("class", "nodes")
        .selectAll("circle")
        .data(nodes_data)
        .enter()
        .append("circle")
        .attr("r", 5)
        .attr("fill", "red")
        .call(d3.drag()
              .on("start", dragstarted)
              .on("drag", dragged)
              .on("end", dragended));


                
function tickActions() {
    //update circle positions each tick of the simulation 
    node
        .attr("cx", function(d) { return d.x; })
        .attr("cy", function(d) { return d.y; });
        
    //update link positions 
    //simply tells one end of the line to follow one node around
    //and the other end of the line to follow the other node around
    link
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

  }                    


function dragstarted(d) {
  if (!d3.event.active) simulation.alphaTarget(0.3).restart();
  d.fx = d.x;
  d.fy = d.y;
}

function dragged(d) {
  d.fx = d3.event.x;
  d.fy = d3.event.y;
}

function dragended(d) {
  if (!d3.event.active) simulation.alphaTarget(0);
  d.fx = null;
  d.fy = null;
}



</script>
"""
	n = size(A,1)
	@assert size(A,2) == n
	ei,ej = findnz(A)[1:2]

	open("fdgraph.html","w") do f 
		write(f,header)
		write(f, "var nodes_data = [")
		for i=1:n
			write(f, "  {\"name\": \"$i\"},\n")
		end
		write(f, "]\n")
		write(f, "var links_data = [")
		for nzi = 1:length(ei)
			i,j = ei[nzi], ej[nzi]
			write(f, "  {\"source\": \"$i\", \"target\": \"$j\"},\n")
		end
		write(f, "]\n")
		# add link data, node data
		write(f,footer)
	end




#=
var nodes_data =  [
    {"name": "Travis", "sex": "M"},
    {"name": "Rake", "sex": "M"},
    {"name": "Diana", "sex": "F"},
    {"name": "Rachel", "sex": "F"},
    {"name": "Shawn", "sex": "M"},
    {"name": "Emerald", "sex": "F"}
    ]
//Create links data 
var links_data = [
    {"source": "Travis", "target": "Rake"},
    {"source": "Diana", "target": "Rake"},
    {"source": "Diana", "target": "Rachel"},
    {"source": "Rachel", "target": "Rake"},
    {"source": "Rachel", "target": "Shawn"},
    {"source": "Emerald", "target": "Rachel"}
]

=#
end