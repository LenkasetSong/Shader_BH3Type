using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[InitializeOnLoad]
public static class ChangeShaderKeywordEditorTool
{
    static ChangeShaderKeywordEditorTool()
    {
        SceneView.onSceneGUIDelegate += OnSceneGUI;
    }

    private static void OnSceneGUI(SceneView sceneView)
    {
        int controlID = GUIUtility.GetControlID(FocusType.Passive);
        if (Event.current.GetTypeForControl(controlID) == EventType.KeyDown)
        {
			if(GameObject.FindGameObjectWithTag("DevTest")==null)
			{
				return;
			}

            if (Event.current.keyCode == KeyCode.A)
            {
                DisableKeyword();
                Shader.EnableKeyword("COLOR_DIFFUSE");
            }
            if (Event.current.keyCode == KeyCode.R)
            {
                DisableKeyword();
                Shader.EnableKeyword("COLOR_R");
            }
            if (Event.current.keyCode == KeyCode.G)
            {
                DisableKeyword();
                Shader.EnableKeyword("COLOR_G");
            }
            if (Event.current.keyCode == KeyCode.B)
            {
                DisableKeyword();
                Shader.EnableKeyword("COLOR_B");
            }
        }
    }

    private static void DisableKeyword()
    {
        Shader.DisableKeyword("COLOR_R");
        Shader.DisableKeyword("COLOR_G");
        Shader.DisableKeyword("COLOR_B");
        Shader.DisableKeyword("COLOR_DIFFUSE");
    }

}
