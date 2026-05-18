const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:5000'

export function requestApi<T>(path: string): Promise<T> {
  return new Promise((resolve, reject) => {
    uni.request({
      url: `${API_BASE_URL}${path}`,
      method: 'GET',
      success: (res) => {
        if (res.statusCode >= 400) {
          reject(res.data)
          return
        }
        resolve(res.data as T)
      },
      fail: reject
    })
  })
}

export function mutateApi<T>(path: string, method: 'POST' | 'PATCH' | 'PUT' | 'DELETE', data?: unknown): Promise<T> {
  return new Promise((resolve, reject) => {
    uni.request({
      url: `${API_BASE_URL}${path}`,
      method,
      data,
      header: {
        'Content-Type': 'application/json'
      },
      success: (res) => {
        if (res.statusCode >= 400) {
          reject(res.data)
          return
        }
        resolve(res.data as T)
      },
      fail: reject
    })
  })
}

export function uploadImageApi<T>(path: string, filePath: string): Promise<T> {
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: `${API_BASE_URL}${path}`,
      filePath,
      name: 'file',
      success: (res) => {
        if (res.statusCode >= 400) {
          reject(res.data)
          return
        }
        try {
          resolve(JSON.parse(res.data) as T)
        } catch (error) {
          reject(error)
        }
      },
      fail: reject
    })
  })
}
