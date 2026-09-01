const TOKEN_KEY = 'sobo_token'

/**
 * localstorage'dan JWT token'ı okur
 */
export function getToken(): string | null {
  if (typeof window === 'undefined') return null
  return localStorage.getItem(TOKEN_KEY)
}

/**
 * JWT token'ı localStorage'a kaydeder
 */
export function setToken(token: string): void {
  if (typeof window === 'undefined') return
  localStorage.setItem(TOKEN_KEY, token)
}

/**
 * JWT token'ı localStorage'dan siler
 */
export function removeToken(): void {
  if (typeof window === 'undefined') return
  localStorage.removeItem(TOKEN_KEY)
}

/**
 * Kullanıcının oturum açıp açmadığını kontrol eder
 */
export function isAuthenticated(): boolean {
  return !!getToken()
}

/**
 * Oturumu kapatır ve giriş sayfasına yönlendirir
 */
export function logout(redirectUrl = '/giris'): void {
  removeToken()
  if (typeof window !== 'undefined') {
    window.location.href = redirectUrl
  }
}

// Alternatif isimlendirmeler için alias export'lar
export const saveToken = setToken
export const clearToken = removeToken
export const getStoredToken = getToken
