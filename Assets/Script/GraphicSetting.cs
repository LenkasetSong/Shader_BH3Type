using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GraphicSetting : MonoBehaviour {

	public Light m_dl;
	public Light m_dlNoShadow;
	public void CloseShadow()
	{
		m_dl.gameObject.SetActive(false);
		m_dlNoShadow.gameObject.SetActive(true);
	}

	public void OpenShadow()
	{
		m_dlNoShadow.gameObject.SetActive(false);
		m_dl.gameObject.SetActive(true);
	}
}
