using UnityEngine;

public class CreateMap : MonoBehaviour
{
    readonly int GridSize = 50;
    public GameObject Tile;

    void Start()
    {
        float scale = 0.1f; // Adjust for more/less gradual transitions

        for (int x = 0; x < GridSize; x++)
        {
            for (int z = 0; z < GridSize; z++)
            {
                float noiseValue = Mathf.PerlinNoise(x * scale, z * scale); // Value between 0 and 1
                float colorValue = Mathf.Lerp(0.4f, 1f, noiseValue); // Scale to a good brightness range

                GameObject newTile = Instantiate(Tile, new Vector2(x, z), Quaternion.identity);
                newTile.GetComponent<SpriteRenderer>().color = new Color(colorValue, colorValue, colorValue);
                newTile.transform.rotation = Quaternion.Euler(0, 0, 90 * Random.Range(0, 4));
            }
        }
    }


}
