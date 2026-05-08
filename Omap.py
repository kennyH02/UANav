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

# G = ox.project_graph(G)
# tag in OSM for places
tags = {"building": True}
places = ox.features_from_place(place, tags)
# places data

nodes=[]
edges=[]
place_nodes = []

# loops through all N / E, takes lat and long from OSM
for node, data in G.nodes(data=True):
    nodes.append({
        "id": str(node),
        "latitude": round(data["y"], 6),
        "longitude": round(data["x"], 6),
        "type": "outdoor_node"
    })

for s, t, data in G.edges(data=True):
        edges.append({
            "source": str(s), 
            "target": str(t),
            "length": data.get("length",1),
            "type": "outdoor_edge"
    })
        
# itterate thru rows of data
for idex, row in places.iterrows():
    if "name" in row and row["name"]:

        # OSM makes center point for N
        lat= row.geometry.centroid.y
        lon = row.geometry.centroid.x

        nearest_node = ox.distance.nearest_nodes(G, lon, lat)
        
        place_nodes.append({
            "name": str(row["name"]),
            "latitude": round(lat, 6),
            "longitude": round(lon, 6),
            "type": "building",
            "node id": str(nearest_node),
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
    latitue[node["id"]] = node["latitude"]
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