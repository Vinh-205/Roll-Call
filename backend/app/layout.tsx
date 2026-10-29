import type { Metadata } from 'next';
import './globals.css';
export const metadata:Metadata={title:'CatCheck · Trương Tuấn Vĩnh 2380602577',description:'API công khai ứng dụng điểm danh nhóm 4 con mèo.'};
export default function Layout({children}:Readonly<{children:React.ReactNode}>){return <html lang='vi'><body>{children}</body></html>}
