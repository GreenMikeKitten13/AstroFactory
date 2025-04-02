using System;
using Unity.Behavior;
using UnityEngine;
using Action = Unity.Behavior.Action;
using Unity.Properties;

[Serializable, GeneratePropertyBag]
[NodeDescription(name: "FindGameObject",
    description: "Get a GameObject in the hierarchy",
    story: "find [GameObjectName] in hierarchy and save in [GameObjectVariable]",
    category: "Action",
    id: "954e69c41d19cb35abf1933a7aad856d")]
public partial class FindGameObjectAction : Action
{
    [SerializeReference] public BlackboardVariable<String> GameObjectName;
    [SerializeReference] public BlackboardVariable<GameObject> GameObjectVariable;
    protected override Node.Status OnUpdate()
    {
        if (GameObjectName == null || GameObjectVariable == null)
        {
            return Node.Status.Failure;
        }

        GameObject obj = GameObject.Find((string)GameObjectName.ObjectValue);

        if (obj == null)
        {
            return Node.Status.Failure;
        }

        GameObjectVariable.ObjectValue = obj;
        return Node.Status.Success;  // Task is successful
    }
}

