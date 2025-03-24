using UnityEngine;

public class CameraScript : MonoBehaviour
{
     GameObject Camera;
     GameObject player;

    private void Awake()
    {
        Camera = GameObject.Find("Main Camera");
        player = GameObject.Find("SpaceShip");
    }
    void Update()
    {
        Camera.transform.position = new Vector3(player.transform.position.x, player.transform.position.y, -10);
    }
}

