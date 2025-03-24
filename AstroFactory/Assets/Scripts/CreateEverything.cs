using Unity.VisualScripting;
using UnityEngine;

public class CreateEverything : MonoBehaviour
{
    public GameObject playerPrefab;
    public GameObject Camera;

    private void Start()
    {
       GameObject player = Instantiate(playerPrefab, Vector3.zero, Quaternion.identity);

        player.AddComponent<PlayerScript>();

        //make Camera child of the player
        Camera.transform.SetParent(player.transform);

    }
}
