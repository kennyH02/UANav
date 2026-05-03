import osmnx as ox
import networkx as nx
import matplotlib.pyplot as mpl
import json as json

# Downloading current maps data
print("Importing campus map from JSON file....")
with open("outside_campus.json") as f:
    outdoor_campus =json.load(f)
# terminal
print("Importing tunnel map from file....")

with open("tunnel.geojson") as f:
    indoor_tunnel = json.load(f)

graph = nx.Graph()
# terminal
print("Adding nodes and edges....")
# node and edge
for node in outdoor_campus["nodes"]:
    graph.add_node(
        node["id"],
        latitue=node["latitue"],
        longitude=node["longitude"],
        type=node["type"]
    )

for edge in outdoor_campus["edges"]:
    graph.add_edge(
        edge["source"],
        edge["target"],
        length=edge["length"],
        type=edge["type"]
    )
# terminal
print("Adding in tunnel information....")
# GJSON information to make N / E from geo
for feature in indoor_tunnel["features"]:
    if feature["geometry"]["type"] == "Point":
        cordinates  = feature["geometry"]["coordinates"]
        node_id = feature["properties"]["id"]
        graph.add_node(
            node_id,
            latitue=cordinates[1],
            longitude=cordinates[0],
            type="tunnel"
        )
# terminal
print("Graph completed.")

nodes=[]
edges=[]
# loops through all N / E, takes lat and long from OSM
for node, data in graph.nodes(data=True):
    nodes.append({
        "id": str(node),
        "latitue": data["y"],
        "longitude": data["x"],
        "type": "outside_campus"
    })
for s, t, data in graph.edges(data=True):
        edges.append({
            "source": str(s),
            "target": str(t),
            "length": data.get("length",1),
            "type": "outside_campus"
    })
    
full_map ={
    "nodes": nodes,
    "edges": edges
}
# json
with open("campus_map.json", "w") as f:
     json.dump(full_map, f, indent=1)
print("Campus map was saved to campus_map.json")



