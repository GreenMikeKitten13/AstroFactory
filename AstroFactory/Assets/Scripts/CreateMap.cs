using UnityEngine;

public class CreateMap : MonoBehaviour
{
    readonly int GridSize = 50;
    public GameObject Tile;

    void Start()
    {
        for (int x = 0; x < GridSize; x++)
        {
            for (int z = 0; z < GridSize; z++)
            {
                Instantiate(Tile, new Vector2(x, z), Quaternion.identity);
            }
        }
    }
}
