extends Node

# Emitted when a physical store section (wall or ground) is clicked
signal section_clicked(section_node : Node2D, section_type: Enums.SectionType)

# Emitted when a specific container (like candy jars) is clicked
signal container_clicked(container_data : GoodsContainerData)
