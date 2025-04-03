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
        player.name = "SpaceShip";

        Camera.AddComponent<CameraScript>();
    }
}
