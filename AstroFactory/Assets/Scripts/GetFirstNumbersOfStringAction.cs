using System;
using Unity.Behavior;
using UnityEngine;
using Action = Unity.Behavior.Action;
using Unity.Properties;

[Serializable, GeneratePropertyBag]
[NodeDescription(name: "getFirstNumbersOfString",
    description: "get the first numbers of a string and save those in the SaveNumbers Variable",
    story: "get [firstNumbers] of [string] and save numbers in [SaveNumbers]",
    category: "Action/Blackboard",
    id: "85ae88e33bcc7444484c172b2cb5d7d8")]
public partial class GetFirstNumbersOfStringAction : Action
{
    [SerializeReference] public BlackboardVariable<int> FirstNumbers;
    [SerializeReference] public BlackboardVariable<string> String;
    [SerializeReference] public BlackboardVariable<int> SaveNumbers;

    protected override Node.Status OnUpdate()
    {
        if (FirstNumbers == null || String == null || SaveNumbers == null)
        {
            return Node.Status.Failure;
        
        }

        string str = String.ObjectValue as string;

        int result = GetFirstThreeCharsAsInt(str);

        static int GetFirstThreeCharsAsInt(string input)
        {
            if (input.Length < 3)
            {
                Debug.LogError("Input string is too short.");
                return 0;
            }

            string firstThreeChars = input[..3];
            if (int.TryParse(firstThreeChars, out int number))
            {
                return number;
            }
            else
            {
                return 0;
            }
        }

        SaveNumbers.ObjectValue = result;
        return Node.Status.Success;  // Task is successful
    }
}

