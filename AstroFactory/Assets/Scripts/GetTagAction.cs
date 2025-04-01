using System;
using Unity.Behavior;
using UnityEngine;
using Action = Unity.Behavior.Action;
using Unity.Properties;

[Serializable, GeneratePropertyBag]
[NodeDescription(name: "GetTag",
    description: "TagSave + GameObject = TagSaveTag",
    story: "TagSave [TagSave] Where to get Tag from [gameobject]",
    category: "Action/Blackboard",
    id: "44fd25dc4481f67dc68802ba784888fa")]
public partial class GetTagAction : Action
{
    [SerializeReference] public BlackboardVariable<GameObject> gameobject;
    [SerializeReference] public BlackboardVariable<string> TagSave;

    protected override Node.Status OnUpdate()
    {
        if (gameobject == null || TagSave == null)
        {
            return Node.Status.Failure;
        }
        GameObject obj = gameobject.ObjectValue as GameObject;
        if (obj == null)
        {
            return Node.Status.Failure;
        }
        TagSave.ObjectValue = obj.tag;
        return Node.Status.Success;  // Task is successful
    }
}

