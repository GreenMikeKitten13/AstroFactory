using System;
using Unity.Behavior;
using UnityEngine;
using Action = Unity.Behavior.Action;
using Unity.Properties;

[Serializable, GeneratePropertyBag]
[NodeDescription(
    name: "Operations",
    description: "a operate b = new a",
    story: "a [Variable] (+ or -) [Operator] b [secVariable] = updated a variable",
    category: "Action/Blackboard",
    id: "1ed75da0ab6f056b4046d1072854db6b")]


public class HealBaseTask : Action
{
    [SerializeReference] public BlackboardVariable Variable; //you need two
    [SerializeReference] public BlackboardVariable secVariable;
    [SerializeReference] public BlackboardVariable Operator; //+ or -

    protected override Node.Status OnUpdate()
    {
       
        if (Variable == null || secVariable == null || Operator == null)
        {
            return Node.Status.Failure;
        }
         //do based on the operator
         if ((string)Operator.ObjectValue == "+")
            Variable.ObjectValue = (int)Variable.ObjectValue + (int)secVariable.ObjectValue;
        else if ((string)Operator.ObjectValue == "-")
            Variable.ObjectValue = (int)Variable.ObjectValue - (int)secVariable.ObjectValue;



        return Node.Status.Success;  // Task is successful
    }
}
