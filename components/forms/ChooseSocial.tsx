"use client"

import React from "react"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import { FaFacebook, FaInstagram, FaLinkedin, FaYoutube } from "react-icons/fa"
import { SiTiktok, SiSnapchat } from "react-icons/si"
import { FaXTwitter } from "react-icons/fa6"

const ChooseSocial = ({ formData, setFormData }: any) => {
  const facebook = typeof window !== "undefined" ? localStorage.getItem("facebook") : ""
  const instagram = typeof window !== "undefined" ? localStorage.getItem("instagram") : ""
  const x = typeof window !== "undefined" ? localStorage.getItem("x") : ""
  const linkedin = typeof window !== "undefined" ? localStorage.getItem("linkedin") : ""
  const youtube = typeof window !== "undefined" ? localStorage.getItem("youtube") : ""
  const tiktok = typeof window !== "undefined" ? localStorage.getItem("tiktok") : ""
  const snapchat = typeof window !== "undefined" ? localStorage.getItem("snapchat") : ""

  const hasSocials =
    (facebook && facebook.length > 3) ||
    (instagram && instagram.length > 3) ||
    (x && x.length > 3) ||
    (linkedin && linkedin.length > 3) ||
    (youtube && youtube.length > 3) ||
    (tiktok && tiktok.length > 3) ||
    (snapchat && snapchat.length > 3)

  if (!hasSocials) {
    return (
      <div className="text-center my-8">
        <p className="text-gray-600">
          Vous n'avez renseigné aucun réseau social. Veuillez mettre à jour votre profil pour que s'affiche ici les réseaux sociaux que vous avez renseignés.
        </p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 my-8">
      {facebook && facebook.length > 3 && (
        <div className="flex w-full my-2 items-center gap-2">
          <FaFacebook size={30} color="#1877F2" />
          <Label className="flex-1">Facebook</Label>
          <Checkbox
            checked={formData.isfacebookchecked || false}
            onCheckedChange={(checked) => {
              setFormData({
                ...formData,
                isfacebookchecked: checked
              })
            }}
          />
        </div>
      )}
      {instagram && instagram.length > 3 && (
        <div className="flex w-full my-2 items-center gap-2">
          <FaInstagram size={30} color="#E4405F" />
          <Label className="flex-1">Instagram</Label>
          <Checkbox
            checked={formData.isinstagramchecked || false}
            onCheckedChange={(checked) => {
              setFormData({
                ...formData,
                isinstagramchecked: checked
              })
            }}
          />
        </div>
      )}
      {x && x.length > 3 && (
        <div className="flex w-full my-2 items-center gap-2">
          <FaXTwitter size={30} color="#1DA1F2" />
          <Label className="flex-1">X</Label>
          <Checkbox
            checked={formData.isxchecked || false}
            onCheckedChange={(checked) => {
              setFormData({
                ...formData,
                isxchecked: checked
              })
            }}
          />
        </div>
      )}
      {linkedin && linkedin.length > 3 && (
        <div className="flex w-full my-2 items-center gap-2">
          <FaLinkedin size={30} color="#0077B5" />
          <Label className="flex-1">LinkedIn</Label>
          <Checkbox
            checked={formData.islinkedinchecked || false}
            onCheckedChange={(checked) => {
              setFormData({
                ...formData,
                islinkedinchecked: checked
              })
            }}
          />
        </div>
      )}
      {youtube && youtube.length > 3 && (
        <div className="flex w-full my-2 items-center gap-2">
          <FaYoutube size={30} color="#FF0000" />
          <Label className="flex-1">YouTube</Label>
          <Checkbox
            checked={formData.isyoutubechecked || false}
            onCheckedChange={(checked) => {
              setFormData({
                ...formData,
                isyoutubechecked: checked
              })
            }}
          />
        </div>
      )}
      {tiktok && tiktok.length > 3 && (
        <div className="flex w-full my-2 items-center gap-2">
          <SiTiktok size={30} color="#000000" />
          <Label className="flex-1">TikTok</Label>
          <Checkbox
            checked={formData.istiktokchecked || false}
            onCheckedChange={(checked) => {
              setFormData({
                ...formData,
                istiktokchecked: checked
              })
            }}
          />
        </div>
      )}
      {snapchat && snapchat.length > 3 && (
        <div className="flex w-full my-2 items-center gap-2">
          <SiSnapchat size={30} color="#FFFC00" />
          <Label className="flex-1">Snapchat</Label>
          <Checkbox
            checked={formData.issnapchatchecked || false}
            onCheckedChange={(checked) => {
              setFormData({
                ...formData,
                issnapchatchecked: checked
              })
            }}
          />
        </div>
      )}
    </div>
  )
}

export default ChooseSocial

