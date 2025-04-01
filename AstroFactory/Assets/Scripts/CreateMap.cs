using UnityEngine;

public class CreateMap : MonoBehaviour
{
    readonly int GridSize = 50;
    public GameObject NormalTile;  // Assign normal tile prefab in Inspector
    public GameObject MountainTile; // Assign mountain tile prefab in Inspector

    void Start()
    {
        float scale = 0.1f; // Adjust for more/less gradual transitions

        for (int x = 0; x < GridSize; x++)
        {
            for (int z = 0; z < GridSize; z++)
            {
                float noiseValue = Mathf.PerlinNoise(x * scale, z * scale); // Value between 0 and 1
                float colorValue = Mathf.Lerp(0.7f, 1f, noiseValue); // Scale to brightness range

                // **Tile Selection Based on Noise**
                GameObject chosenTile = (noiseValue > 0.6f) ? MountainTile : NormalTile;

                GameObject newTile = Instantiate(chosenTile, new Vector2(x, z), Quaternion.identity);
                if (chosenTile != MountainTile)
                    newTile.GetComponent<SpriteRenderer>().color = new Color(colorValue, colorValue, colorValue);
                newTile.transform.rotation = Quaternion.Euler(0, 0, 90 * Random.Range(0, 4));
            }
        }
    }
}
