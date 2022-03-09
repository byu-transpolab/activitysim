i <- 1
j <- 1
k <- 1

person1 <- unique(plans$person_id)[j]

personxml <- xml_new_root("person")
xml_set_attr(xml_find_first(personxml, "/person"),
             "id",
             paste0("\"", person1, "\"")
             )

attributesxml <- xml_new_root("attributes")
for(n in 1:3) xml_add_child(attributesxml, "attribute")
attributenodes <- xml_find_all(attributesxml, "/attributes/attribute")
xml_set_attrs(attributenodes[1], c(class="java.lang.Integer", name="age"))
xml_text(attributenodes[1]) <- as.character(persons["person_id"==person1,"age"])

plansxml <- xml_new_root("plan")
xml_set_attr(xml_find_first(plansxml, "/plan"), "selected", "yes")

plans1 <- filter(plans, person_id == unique(plans$person_id)[j])

for(i in 1:nrow(plans1)){
  
  activityxml <- xml_new_root("activity")
  activitynode <- xml_find_first(activityxml, "/activity")
  
  if(!is.na(plans1[i,"departure_time"])){
    xml_set_attr(activitynode, "end_time", plans1[i,"departure_time"])
  }
  xml_set_attr(activitynode, "y", plans1[i,"y"])
  xml_set_attr(activitynode, "x", plans1[i,"x"])
  xml_set_attr(activitynode, "type", plans1[i,"ActivityType"])
  
  xml_add_child(xml_find_first(plansxml, "/plan"), activityxml)
}
