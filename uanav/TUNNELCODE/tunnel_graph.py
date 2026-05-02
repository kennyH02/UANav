import json
import math

print("Importing tunnel path data...")

with open("tunnelpaths.geojson") as f:
    tunnel_paths = json.load(f)

graph_nodes = {}
edges = []

node_count = 1
edge_count = 1


def get_node_id(coord):
    global node_count

    # GeoJSON coordinates are [x, y]
    x = round(coord[0], 6)
    y = round(coord[1], 6)
    key = (x, y)

    if key not in graph_nodes:
        node_id = f"T{node_count:03}"

        graph_nodes[key] = {
            "id": node_id,
            "latitue": y,
            "longitude": x,
            "type": "tunnel"
        }

        node_count += 1

    return graph_nodes[key]["id"]


def calculate_length(point_a, point_b):
    x1, y1 = point_a
    x2, y2 = point_b

    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)


print("Creating tunnel nodes and edges...")

for feature in tunnel_paths["features"]:
    geometry = feature["geometry"]

    if geometry["type"] != "LineString":
        continue

    coordinates = geometry["coordinates"]

    for i in range(len(coordinates) - 1):
        start_coord = coordinates[i]
        end_coord = coordinates[i + 1]

        source_id = get_node_id(start_coord)
        target_id = get_node_id(end_coord)

        edge = {
            "id": f"TE{edge_count:03}",
            "source": source_id,
            "target": target_id,
            "length": calculate_length(start_coord, end_coord),
            "type": "tunnel"
        }

        edges.append(edge)
        edge_count += 1


nodes = list(graph_nodes.values())

tunnel_map = {
    "nodes": nodes,
    "edges": edges
}

with open("tunnel_map.json", "w") as f:
    json.dump(tunnel_map, f, indent=2)

print("Tunnel graph completed.")
print(f"Created {len(nodes)} tunnel nodes.")
print(f"Created {len(edges)} tunnel edges.")
print("Tunnel map was saved to tunnel_map.json")