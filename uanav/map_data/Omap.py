# imports
import osmnx as ox
import networkx as nx
import matplotlib.pyplot as mpl
import json as json
# location
place = "University at Albany, New York, USA"
# terminal message
print("Downloading street data for the University at Albany")
# download openstreetmap data

G = ox.graph_from_place(place, network_type="walk")
# tag in OSM for places
tags = {"building": True}
places = ox.features_from_place(place, tags)
# places data

nodes=[]
edges=[]
# loops through all N / E, takes lat and long from OSM
for node, data in G.nodes(data=True):
    nodes.append({
        "id": str(node),
        "latitue": data["y"],
        "longitude": data["x"],
    })

for s, t, data in G.edges(data=True):
        edges.append({
            "source": str(s), 
            "target": str(t),
            "length": data.get("length",1),
    })
        
place_nodes = []
# itterate thru rows of data
for idex, row in places.iterrows():
    if "name" in row and row["name"]:
        place_nodes.append({
            "name": str(row["name"]),
            # OSM makes center point for N
            "lat": row.geometry.centroid.y,
            "lon": row.geometry.centroid.x,
          })

# JSON FILES
with open("node.json", "w") as f:
     json.dump(nodes,f, indent =1)

with open("edge.json", "w") as f:
     json.dump(edges,f, indent =1)

with open("place.json", "w") as f:
     json.dump(place_nodes,f, indent =1)

print("Campus map was saved to json files")


# with open("outside_campus.json") as f:
#         data = json.load(f)
# grapgh
latitue ={}
longitude ={}

for node in nodes:
    latitue[node["id"]] = node["latitue"]
    longitude[node["id"]] = node["longitude"]

for edge in edges:
    s = edge["source"]
    t = edge["target"]
    x = [longitude[s], longitude[t]]
    y = [latitue[s], latitue[t]]

    mpl.plot(x,y, color = "purple", linewidth =0.5)

mpl.title("UANav Nodes and Edges")
mpl.xlabel("longitude")
mpl.ylabel("latitue")
mpl.show()